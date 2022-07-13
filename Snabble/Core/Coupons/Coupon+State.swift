//
//  Coupon+State.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation

public extension Coupon {
    var isActivated: Bool {
        UserDefaults.standard.stringArray(forKey: stateKey)?.contains(where: { $0 == id }) ?? false
    }

    func activate() {
        switchTo(.activate)
    }

    func deactivate() {
        switchTo(.deactivate)
    }

    private enum State {
        case activate
        case deactivate
    }

    private func switchTo(_ state: State) {
        let couponIds = UserDefaults.standard.stringArray(forKey: stateKey) ?? []
        var idSet = couponIds.reduce(into: Set<String>()) { partialResult, object in
            partialResult.insert(object)
        }

        switch state {
        case .activate:
            idSet.insert(id)
        case .deactivate:
            idSet.remove(id)
        }

        UserDefaults.standard.set(Array(idSet), forKey: stateKey)
    }

    private var stateKey: String { "io.snabble.couponsActivated.\(projectID.rawValue)" }
}
