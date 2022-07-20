//
//  Coupon+State.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation

extension Coupon {
    var stateKey: String { "io.snabble.couponsActivated.\(projectID.rawValue)" }

    public var isActivated: Bool {
        UserDefaults.standard.stringArray(forKey: stateKey)?.contains(where: { $0 == id }) ?? false
    }

    public var isValid: Bool {
        let now = Date()
        switch (validFrom, validUntil) {
        case (.none, .none):
            return false
        case (.some(let validFrom), .none):
            return now >= validFrom
        case (.none, .some(let validUntil)):
            return now <= validUntil
        case (.some(let validFrom), .some(let validUntil)):
            return now >= validFrom && now <= validUntil
        }
    }
}
