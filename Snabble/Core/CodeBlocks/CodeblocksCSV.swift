//
//  CodeblocksCSV.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//
//  generate a csv QR code

struct CodeblocksCSV {

    private let config: QRCodeConfig

    init(_ config: QRCodeConfig) {
        self.config = config
    }

    func generateQrCodes(_ cart: ShoppingCart) -> [String] {
        var lines = [String]()
        if let card = cart.customerCard {
            lines.append("1;\(card)")
        }

        lines += cart.items.reduce(into: [], { result, item in
            let qrCode = QRCodeData(item)
            result.append("\(qrCode.quantity);\(qrCode.code)")
        })

        let chunks = self.divideIntoChunks(lines, maxCodes: self.config.maxCodes)

        let blocks: [[String]] = chunks.enumerated().map { index, chunk in
            let header = self.config.format == .csv ? "snabble;\(index+1);\(chunks.count)" : "snabble;"
            return [ header ] + chunk
        }

        return blocks.map { $0.joined(separator: self.config.separator) }
    }

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
}
