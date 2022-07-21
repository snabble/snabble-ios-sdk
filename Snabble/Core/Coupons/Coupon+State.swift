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
}
