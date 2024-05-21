//
//  Decimal.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

// convenience methods for `Decimal`

import Foundation

extension Decimal {
    var intValue: Int {
        (self as NSDecimalNumber).intValue
    }

    mutating func round(mode roundingMode: SnabbleCore.RoundingMode, scale: Int = 0) {
        var value = self
        NSDecimalRound(&self, &value, scale, roundingMode.mode)
    }

    func rounded(mode roundingMode: SnabbleCore.RoundingMode, scale: Int = 0) -> Decimal {
        var result = Decimal.zero
        var value = self
        NSDecimalRound(&result, &value, scale, roundingMode.mode)
        return result
    }
}
