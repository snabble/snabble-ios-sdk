//
//  CodeblocksIKEA.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

fileprivate struct CodeBucket {
    var familyCard: String?
    var codes: [String]
    var lots: Int?

    static let formatter: NumberFormatter = {
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 2
        return fmt
    }()

    let gs = "\u{001d}" // ASCII Group Separator

    init(_ codes: [String] = []) {
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
            lot = "10" + CodeBucket.formatter.string(for: lots)! + gs
        }

        // AI 92 (additional item id), card number
        var familyCard = ""
        if let card = self.familyCard {
            familyCard = "92" + card + gs
        }

        // AI 240 (additional item id)
        let codes = self.codes.map { "240" + $0 }.joined(separator: gs)

        return header + lot + familyCard + codes
    }
}

struct CodeblocksIKEA {

    private let config: QRCodeConfig

    init(_ config: QRCodeConfig) {
        self.config = config
    }

    func generateQrCodes(_ cart: ShoppingCart, _ lines: [String]) -> [String] {
        let maxChars = self.config.maxChars ?? 198
        return self.codes(cart, lines, maxChars)
    }

    private func codes(_ cart: ShoppingCart, _ lines: [String], _ maxChars: Int) -> [String] {
        var buckets = [CodeBucket]()
        var bucket = CodeBucket()

        for (index, item) in lines.enumerated() {
            if index == 0 {
                bucket.familyCard = cart.customerCard
            }
            bucket.codes.append(item)

            // too large? start a new bucket
            if bucket.size > maxChars {
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
}
