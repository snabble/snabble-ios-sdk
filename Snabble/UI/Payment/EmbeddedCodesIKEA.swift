//
//  EmbeddedCodesIKEA.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

fileprivate extension QRCodeData {
    static let formatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 2
        return fmt
    }()

    var size: Int {
        return string.count
    }

    var string: String {
        // AI 240 (additional item ids), item's scanned code
        if self.quantity == 1 {
            return "240" + self.code
        } else {
            // AI 30 (count of items), quantity
            return "240" + self.code + "30" + QRCodeData.formatter.string(for: self.quantity)!
        }
    }
}

fileprivate struct CodeBucket {
    var card: String?
    var codes: [QRCodeData]
    var lots: Int?

    let gs = "\u{001d}" // ASCII Group Separator

    init(_ codes: [QRCodeData] = []) {
        self.codes = codes
    }

    var size: Int {
        return string.count
    }

    var string: String {
        // AI 91 (origin type), 00003 == IKEA Store App
        let header = "9100003" + gs

        // AI 10 (lot number), # of chunks
        var lot = "10__" + gs
        if let lots = self.lots {
            lot = "10" + QRCodeData.formatter.string(for: lots)! + gs
        }

        // AI 92 (additional item id), card number
        var familyCard = ""
        if let card = self.card {
            familyCard = "92" + card + gs
        }

        return header + lot + familyCard + codes.map { $0.string }.joined(separator: gs)
    }
}

struct EncodedCodesIKEA {

    static func codes(_ cart: ShoppingCart, _ familyCard: String?, maxBytes: Int) -> [String] {
        var buckets = [CodeBucket]()
        var bucket = CodeBucket()

        let codes = cart.items.map { $0.dataForQR }

        for (index, item) in codes.enumerated() {
            if index == 0 {
                bucket.card = familyCard
            }
            bucket.codes.append(item)

            // too large? start a new bucket
            if bucket.size > maxBytes {
                let last = bucket.codes.popLast()
                buckets.append(bucket)

                bucket = CodeBucket([last!])
            }
        }
        // add the current bucket
        buckets.append(bucket)

        // set the count now that we know it
        for i in 0 ..< buckets.count {
            buckets[i].lots = buckets.count
        }

        return buckets.map { $0.string }
    }

    static func codes(_ chunks: [[String]], _ familyCard: String?) -> [String] {
        let gs = "\u{001d}" // ASCII Group Separator
        let blocks = chunks.enumerated().map { index, block -> String in
            // AI 91 (origin type), 00003 == IKEA Store App
            let header = "9100003"

            // AI 10 (lot number), # of chunks
            let lots = "10" + QRCodeData.formatter.string(for: chunks.count)!

            var result = header + gs + lots + gs

            // family card goes into the first code
            if let card = familyCard, index == 0 {
                let familyCard = "92" + card        // AI 92 (additional item id), card number
                result += familyCard + gs
            }

            let items = block.map { "240" + $0 }    // AI 240 (additional item ids), item's scanned code
            return result + items.joined(separator: gs)
        }

        return blocks
    }

}
