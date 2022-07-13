//
//  Coupon+State.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation

public extension Coupon {

    var isActivated: Bool {
        get {
            UserDefaults.standard.couponsActivated.contains(where: { $0 == id })
        }
        set {
            switchTo(newValue ? .activate : .deactivate)
        }
    }

    private enum State {
        case activate
        case deactivate
    }

    private func switchTo(_ state: State ) {
        let couponIds = UserDefaults.standard.couponsActivated
        var idSet = couponIds.reduce(into: Set<String>()) { partialResult, object in
            partialResult.insert(object)
        }

        switch state {
        case .activate:
            idSet.insert(id)
        case .deactivate:
            idSet.remove(id)
        }

        UserDefaults.standard.couponsActivated = Array(idSet)
    }
}

extension UserDefaults {
    private static let stateKey = "io.snabble.couponsActivated"

    @objc var couponsActivated: [String] {
        get {
            stringArray(forKey: Self.stateKey) ?? []
        }
        set {
            set(newValue, forKey: Self.stateKey)
        }
    }
}
