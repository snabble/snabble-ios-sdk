//
//  Codeblocks.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

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
    var endCode: String?

    init(_ config: QRCodeConfig) {
        self.config = config
        self.endCode = config.nextCode
        self.items = []
    }

    var count: Int {
        return items.count + (cardCode != nil ? 1 : 0)
    }

    func hasRoom(for item: CodeBlockItem) -> Bool {
        if let maxChars = config.maxChars {
            let str = self.stringify(1, 10)
            return str.count + self.codeLength(item) < maxChars
        } else {
            return self.count < self.config.effectiveMaxCodes
        }
    }

    func codeLength(_ item: CodeBlockItem) -> Int {
        let sep = self.config.separator.count
        switch self.config.format {
        case .simple: return item.code.count + sep
        case .csv, .csv_globus: return item.code.count + "\(item.quantity)".count + sep
        case .ikea: return item.code.count + 4 // "240" + GS
        case .unknown: return 0
        }
    }

    func stringify(_ index: Int, _ total: Int) -> String {
        switch config.format {
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
        if let end = self.endCode {
            codes.append(end)
        }

        return config.prefix + codes.joined(separator: config.separator) + config.suffix
    }

    private func csvStringify(_ index: Int, _ total: Int) -> String {
        var codes = self.items.map { "\($0.quantity);\($0.code)" }
        if let card = self.cardCode {
            codes.insert("1;\(card)", at: 0)
        }
        if let end = self.endCode {
            codes.append("1;\(end)")
        }

        let header = config.format == .csv ? "snabble;\(index+1);\(total)" : "snabble;"

        return header + config.separator + codes.joined(separator: config.separator)
    }

    private static let formatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 2
        return fmt
    }()

    private func ikeaStringify(_ total: Int) -> String {
        var codes = self.items.map { "240" + $0.code }
        if let card = self.cardCode {
            codes.insert("92" + card, at: 0)
        }
        if let end = self.endCode {
            codes.append("240" + end)
        }

        let gs = "\u{1d}" // ascii GROUP SEPARATOR, 0x1d

        // AI 91 (origin type), 00003 == IKEA Store App
        let header = "9100003" + gs

        // AI 10 (lot number), # of chunks
        let lot = "10" + Codeblock.formatter.string(for: total)! + gs

        return header + lot + codes.joined(separator: gs)
    }
}

struct Codeblocks {
    static func generateQrCodes(_ cart: ShoppingCart, _ config: QRCodeConfig) -> [String] {
        let blocks = makeBlocks(cart, config)

        blocks.forEach { assert($0.items.count <= config.maxCodes) }
        
        let codes = blocks.enumerated().map { (index, block) in
            block.stringify(index, blocks.count)
        }

        return codes
    }

    private static func makeBlocks(_ cart: ShoppingCart, _ config: QRCodeConfig) -> [Codeblock] {
        if let nextWithCheck = config.nextCodeWithCheck {
            // separate regular/restricted items
            let regularItems = cart.items.filter { $0.product.saleRestriction == .none }
            let restrictedItems = cart.items.filter { $0.product.saleRestriction != .none }

            var customerCard = cart.customerCard
            var regularBlocks = makeBlocks(regularItems, config, customerCard)
            if regularBlocks.count > 0 {
                customerCard = nil
            }

            let restrictedBlocks = makeBlocks(restrictedItems, config, customerCard)

            // if there is no regular block, fake one so that we have a place to put the `nextWithCheck` code
            if regularBlocks.count == 0 && restrictedBlocks.count > 0 {
                let block = Codeblock(config)
                regularBlocks = [ block ]
            }

            // patch the last regular block to have the `nextWithCheck` code
            regularBlocks[regularBlocks.count - 1].endCode = nextWithCheck

            // optional TODOs:
            // - if there is at least one regular and one restricted block, merge the last of the regular blocks into the first restricted
            // - balance regular and restricted blocks so that they contain an equal number of lines

            // patch the last of all blocks to have the `finalCode` code
            var allBlocks = regularBlocks + restrictedBlocks
            allBlocks[allBlocks.count - 1].endCode = config.finalCode

            return allBlocks
        } else {
            // all items are considered "regular"
            var allBlocks = makeBlocks(cart.items, config, cart.customerCard)
            allBlocks[allBlocks.count - 1].endCode = config.finalCode
            return allBlocks
        }
    }

    private static func makeBlocks(_ items: [CartItem], _ config: QRCodeConfig, _ customerCard: String?) -> [Codeblock] {
        var result = [Codeblock]()

        var currentBlock = Codeblock(config)
        for (index, item) in items.enumerated() {
            if index == 0, let card = customerCard {
                currentBlock.cardCode = card
            }

            let cartItem = item.cartItem
            if config.format.repeatCodes {
                for _ in 0 ..< item.quantity {
                    let item = CodeBlockItem(1, cartItem.scannedCode)
                    if !currentBlock.hasRoom(for: item) {
                        result.append(currentBlock)
                        currentBlock = Codeblock(config)
                    }
                    currentBlock.items.append(item)
                }
            } else {
                let item = CodeBlockItem(cartItem.amount, cartItem.scannedCode)
                if !currentBlock.hasRoom(for: item) {
                    result.append(currentBlock)
                    currentBlock = Codeblock(config)
                }
                currentBlock.items.append(item)
            }
        }

        if currentBlock.count > 0 {
            result.append(currentBlock)
        }

        return result
    }
}

/*
 private func divideIntoChunks(_ lines: [String], maxCodes: Int) -> [[String]] {
 let maxCodes = Float(maxCodes)
 let linesCount = Float(lines.count)
 let chunks = (linesCount / maxCodes).rounded(.up)
 let chunkSize = Int((linesCount / chunks).rounded(.up))
 let blocks = stride(from: 0, to: lines.count, by: chunkSize).map { start -> [String] in
 return Array(lines[start ..< min(start + chunkSize, lines.count)])
 }
 return blocks
 }
 */
