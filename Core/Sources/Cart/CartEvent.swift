//
//  CartEvent.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// MARK: send events
public enum CartEvent: Sendable {
    static func sessionStart(_ cart: ShoppingCart) {
        guard !cart.shopId.rawValue.isEmpty else {
            return
        }

        guard let project = Snabble.shared.project(for: cart.projectId) else {
            return
        }

        let event = AppEvent(.sessionStart, session: cart.session, project: project, shopId: cart.shopId)
        event.post()
    }

    static func sessionEnd(_ cart: ShoppingCart) {
        guard !cart.shopId.rawValue.isEmpty else {
            return
        }

        guard let project = Snabble.shared.project(for: cart.projectId) else {
            return
        }

        let event = AppEvent(.sessionEnd, session: cart.session, project: project, shopId: cart.shopId)
        event.post()
    }

    public static func cart(_ cart: ShoppingCart) {
        if cart.shopId.rawValue.isEmpty || (cart.numberOfItems == 0 && cart.session.isEmpty) {
            return
        }

        cart.createCheckoutInfo(completion: { _ in })
        let event = AppEvent(cart)
        event?.post()
    }
}
