//
//  Codeblocks.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

struct Codeblocks {
    static func generateQrCodes(_ cart: ShoppingCart, _ config: QRCodeConfig) -> [String] {
        switch config.format {
        case .simple:
            let codeblocks = CodeblocksSimple(config)
            return codeblocks.generateQrCodes(cart)
        case .csv, .csv_globus:
            let codeblocks = CodeblocksCSV(config)
            return codeblocks.generateQrCodes(cart)
        case .ikea:
            let codeblocks = CodeblocksIKEA(config)
            return codeblocks.generateQrCodes(cart)
        case .unknown:
            Log.error("unknown QR code format")
            return []
        }
    }
}

/// quantity and code string for embedding in a QR code
struct QRCodeData {
    public let quantity: Int
    public let code: String

    init(_ quantity: Int, _ code: String) {
        self.quantity = quantity
        self.code = code
    }

    init(_ item: CartItem) {
        let cartItem = item.cartItem
        self.init(cartItem.amount, cartItem.scannedCode)
    }

    static func codesFor(_ items: [CartItem]) -> [String] {
        return items.reduce(into: [], { result, item in
            let qrCode = QRCodeData(item)
            let arr = Array(repeating: qrCode.code, count: qrCode.quantity)
            result.append(contentsOf: arr)
        })
    }
}

