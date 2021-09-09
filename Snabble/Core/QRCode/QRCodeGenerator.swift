//
//  QRCodeGenerator.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

/// generate QR code(s) for offline payment
public struct QRCodeGenerator {
    private var cart: ShoppingCart
    private var config: QRCodeConfig

    /// - Parameters:
    ///   - cart: the `ShoppingCart`
    ///   - config: the `QRCodeConfig`
    public init(_ cart: ShoppingCart, _ config: QRCodeConfig) {
        self.cart = cart
        self.config = config
    }

    /// generate the QR code strings for a shopping cart
    /// - Returns: an array of strings to be rendered as QR codes
    public func generateCodes() -> [String] {
        let blocks = self.makeBlocks()

        if self.config.maxChars == nil {
            blocks.forEach { assert($0.items.count <= self.config.maxCodes) }
        }

        let codes = blocks.enumerated().map { (index, block) in
            block.stringify(index, blocks.count)
        }

        if let maxChars = self.config.maxChars {
            codes.forEach { assert($0.count <= maxChars) }
        }

        return codes
    }

    // split the cart into as many blocks as needed
    private func makeBlocks() -> [Codeblock] {
        if let nextWithCheck = self.config.nextCodeWithCheck {
            // separate regular and restricted itms
            return self.splitCart(nextWithCheck)
        }

        // all items are considered "regular"
        let items = self.cart.items
        let coupons = self.cart.coupons
        var blocks = self.makeBlocks(items, coupons, self.cart.customerCard)

        // patch the last block to have the `finalCode` code
        if let finalCode = self.config.finalCode {
            blocks[blocks.count - 1].endCodes = [finalCode]
        } else {
            blocks[blocks.count - 1].endCodes = []
        }

        // if there are any manual discounts, append the `manualDiscountFinalCode`
        let manualDiscountUsed = self.cart.items.firstIndex { $0.manualCoupon != nil } != nil
        if manualDiscountUsed, let manualDiscountFinalCode = self.config.manualDiscountFinalCode {
            blocks[blocks.count - 1].endCodes.append(manualDiscountFinalCode)
        }
        return self.balanceBlocks(blocks)
    }

    // split the cart into blocks of regular items, followed by blocks of restricted items
    private func splitCart(_ nextWithCheck: String) -> [Codeblock] {
        let regularItems = self.cart.items.filter { $0.product.saleRestriction == .none }
        let restrictedItems = self.cart.items.filter { $0.product.saleRestriction != .none }

        var customerCard = cart.customerCard
        var coupons = self.cart.coupons
        var regularBlocks = self.makeBlocks(regularItems, coupons, customerCard)
        if !regularBlocks.isEmpty {
            customerCard = nil
            coupons = []
        }
        var restrictedBlocks = self.makeBlocks(restrictedItems, coupons, customerCard)

        // if there is no regular block, fake one so that we have a place to put the `nextWithCheck` code
        if regularBlocks.isEmpty && !restrictedBlocks.isEmpty {
            let block = Codeblock(self.config)
            regularBlocks = [ block ]
        }

        // if possible, merge the last regular and the last restricted block
        if regularBlocks.count > 1 && !restrictedBlocks.isEmpty && self.config.maxChars == nil {
            let lastRegularIndex = regularBlocks.count - 1
            let lastRestrictedIndex = restrictedBlocks.count - 1

            if regularBlocks[lastRegularIndex].count + restrictedBlocks[lastRestrictedIndex].count <= self.config.effectiveMaxCodes {
                restrictedBlocks[lastRestrictedIndex].items.append(contentsOf: regularBlocks[lastRegularIndex].items)
                regularBlocks.remove(at: lastRegularIndex)
            }
        }

        regularBlocks = self.balanceBlocks(regularBlocks)
        restrictedBlocks = self.balanceBlocks(restrictedBlocks)

        // patch the last regular block to have the `nextWithCheck` code
        regularBlocks[regularBlocks.count - 1].endCodes = [nextWithCheck]

        // patch the last of all blocks to have the `finalCode` code
        var allBlocks = regularBlocks + restrictedBlocks
        if let finalCode = self.config.finalCode {
            allBlocks[allBlocks.count - 1].endCodes = [finalCode]
        }

        // if there are any manual discounts, append the `manualDiscountFinalCode`
        let manualDiscountUsed = self.cart.items.firstIndex { $0.manualCoupon != nil } != nil
        if manualDiscountUsed, let manualDiscountFinalCode = self.config.manualDiscountFinalCode {
            allBlocks[allBlocks.count - 1].endCodes.append(manualDiscountFinalCode)
        }

        return allBlocks
    }

    // split a list of cart items into as many `CodeBlock`s as needed
    private func makeBlocks(_ items: [CartItem], _ coupons: [CartCoupon], _ customerCard: String?) -> [Codeblock] {
        var result = [Codeblock]()
        var currentBlock = Codeblock(self.config)

        // coupons go into the first block
        for coupon in coupons where coupon.scannedCode != nil {
            let item = CodeBlockItem(1, coupon.scannedCode!)
            self.append(item, to: &currentBlock, &result)
        }

        for (index, item) in items.enumerated() {
            // if we have a customer card, it goes into the first block
            if index == 0, let card = customerCard {
                currentBlock.cardCode = card
            }

            for cartItem in item.cartItems {
                guard case let Cart.Item.product(productItem) = cartItem else {
                    continue
                }

                let code = getCode(for: item, productItem)

                if self.config.format.repeatCodes {
                    for _ in 0 ..< productItem.amount {
                        let item = CodeBlockItem(1, code)
                        self.append(item, to: &currentBlock, &result)
                    }
                } else {
                    let item = CodeBlockItem(productItem.amount, code)
                    self.append(item, to: &currentBlock, &result)
                }
            }
        }

        // swiftlint:disable:next empty_count
        if currentBlock.count > 0 {
            result.append(currentBlock)
        }

        return result
    }

    private func getCode(for item: CartItem, _ productItem: Cart.ProductItem) -> String {
        if let transmitTemplate = item.scannedCode.transmissionTemplateId,
           let code = CodeMatcher.createInstoreEan(transmitTemplate, item.scannedCode.lookupCode, item.scannedCode.embeddedData ?? 0) {
            return code
        } else {
            return productItem.scannedCode
        }
    }

    private func append(_ item: CodeBlockItem, to currentBlock: inout Codeblock, _ result: inout [Codeblock]) {
        if !currentBlock.hasRoom(for: item) {
            result.append(currentBlock)
            currentBlock = Codeblock(self.config)
        }
        currentBlock.items.append(item)
    }

    // try to balance the number of codes in each blocks
    private func balanceBlocks(_ blocks: [Codeblock]) -> [Codeblock] {
        // doesn't work if we have a character limit
        guard self.config.maxChars == nil else {
            return blocks
        }

        let items = blocks.flatMap { $0.items }
        guard !items.isEmpty else {
            return blocks
        }

        let chunks = self.divideIntoChunks(items, self.config.effectiveMaxCodes)
        if chunks.count == blocks.count && chunks[0].count < blocks[0].count - 3 {
            var newBlocks = blocks
            for idx in 0 ..< chunks.count {
                newBlocks[idx].items = chunks[idx]
            }
            return newBlocks
        } else {
            return blocks
        }
    }

    private func divideIntoChunks(_ items: [CodeBlockItem], _ maxCodes: Int) -> [[CodeBlockItem]] {
        let maxCodes = Float(maxCodes)
        let itemCount = Float(items.count)
        let chunks = (itemCount / maxCodes).rounded(.up)
        let chunkSize = Int((itemCount / chunks).rounded(.up))
        let blocks = stride(from: 0, to: items.count, by: chunkSize).map { start -> [CodeBlockItem] in
            return Array(items[start ..< min(start + chunkSize, items.count)])
        }
        return blocks
    }

}

private struct CodeBlockItem {
    let quantity: Int
    let code: String

    init(_ quantity: Int, _ code: String) {
        self.quantity = quantity
        self.code = code
    }
}

private struct Codeblock {
    let config: QRCodeConfig
    var cardCode: String?
    var items: [CodeBlockItem]
    var endCodes: [String]

    init(_ config: QRCodeConfig) {
        self.config = config
        self.items = []
        if let nextCode = config.nextCode {
            self.endCodes = [nextCode]
        } else {
            self.endCodes = []
        }
    }

    var count: Int {
        return self.items.count + (self.cardCode != nil ? 1 : 0)
    }

    func hasRoom(for item: CodeBlockItem) -> Bool {
        let str = self.stringify(1, 10)
        if let maxChars = self.config.maxChars {
            return str.count + self.codeLength(item) < maxChars
        } else {
            let countOK = self.count < self.config.effectiveMaxCodes
            let charsOK = str.count + self.codeLength(item) <= QRCodeConfig.qrCodeMax
            return countOK && charsOK
        }
    }

    private func codeLength(_ item: CodeBlockItem) -> Int {
        let sep = self.config.separator.count
        switch self.config.format {
        case .simple:
            return item.code.count + sep
        case .csv, .csv_globus:
            return item.code.count + "\(item.quantity)".count + sep
        case .ikea:
            return item.code.count + 4 // "240" + GS
        case .unknown:
            return 0
        }
    }

    func stringify(_ index: Int, _ total: Int) -> String {
        switch self.config.format {
        case .simple:
            return self.simpleStringify()
        case .csv, .csv_globus:
            return self.csvStringify(index, total)
        case .ikea:
            return self.ikeaStringify(total)
        case .unknown:
            return ""
        }
    }

    private func simpleStringify() -> String {
        var codes = self.items.map { $0.code }
        if let card = self.cardCode {
            codes.insert(card, at: 0)
        }
        codes.append(contentsOf: self.endCodes)

        return self.config.prefix + codes.joined(separator: self.config.separator) + config.suffix
    }

    private func csvStringify(_ index: Int, _ total: Int) -> String {
        var codes = self.items.map { "\($0.quantity);\($0.code)" }
        if let card = self.cardCode {
            codes.insert("1;\(card)", at: 0)
        }
        self.endCodes.forEach {
            codes.append("1;\($0)")
        }

        let header = self.config.format == .csv ? "snabble;\(index + 1);\(total)" : "snabble;"

        return header + self.config.separator + codes.joined(separator: self.config.separator)
    }

    private static let formatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 2
        return fmt
    }()

    private func ikeaStringify(_ total: Int) -> String {
        var codes = self.items.map { "240\($0.code)" }
        if let card = self.cardCode {
            codes.insert("92" + card, at: 0)
        }
        self.endCodes.forEach {
            codes.append("240\($0)")
        }

        let sep = "\u{1d}" // ascii GROUP SEPARATOR, 0x1d

        // AI 91 (origin type), 00003 == IKEA Store App
        let header = "9100003\(sep)"

        // AI 10 (lot number), # of chunks
        let lot = "10" + Codeblock.formatter.string(for: total)! + sep

        return header + lot + codes.joined(separator: sep)
    }
}
