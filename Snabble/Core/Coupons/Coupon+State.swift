//
//  Coupon+State.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation

extension Coupon {
    public var isActivated: Bool {
        UserDefaults.standard.stringArray(forKey: stateKey)?.contains(where: { $0 == id }) ?? false
    }

    var stateKey: String { "io.snabble.couponsActivated.\(projectID.rawValue)" }
}
