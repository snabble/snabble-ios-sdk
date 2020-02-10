//
//  CartEvent.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// MARK: send events
struct CartEvent {
    static func sessionStart(_ cart: ShoppingCart) {
        guard cart.shopId != "" else {
            return
        }

        guard let project = SnabbleAPI.projectFor(cart.projectId) else {
            return
        }

        let event = AppEvent(.sessionStart, session: cart.session, project: project, shopId: cart.shopId)
        event.post()
    }

    static func sessionEnd(_ cart: ShoppingCart) {
        guard cart.shopId != "" else {
            return
        }

        guard let project = SnabbleAPI.projectFor(cart.projectId) else {
            return
        }

        let event = AppEvent(.sessionEnd, session: cart.session, project: project, shopId: cart.shopId)
        event.post()
    }

    static func cart(_ cart: ShoppingCart) {
        if cart.shopId == "" || (cart.items.count == 0 && cart.session == "") {
            return
        }

        cart.createCheckoutInfo(completion: {_ in})
        let event = AppEvent(cart)
        event?.post()
    }
}
