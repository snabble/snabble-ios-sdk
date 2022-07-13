//
//  ShoppingCartManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.07.22.
//

import Foundation

public final class ShoppingCartManager {
    static let shared = ShoppingCartManager()

    private(set) var cart: ShoppingCart?

    private init() {
        cart = nil
    }

    func update(with shop: Shop) {
        if shop.id != cart?.shopId {
            let config = CartConfig(shop: shop)
            cart = ShoppingCart(config)
        }
        cart?.updateProducts()
    }

//    func changeCart(shop: Shop) {
//        let config = CartConfig(shop: shop)
//        cart = ShoppingCart(config)
//        cart?.updateProducts()
//    }

    func updateCustomerCard(_ customerCard: Any) {
//        cart?.customerCard = customerCard
//        self.cart?.customerCard = Snabble.shared.project(for: shop.projectId)?.getMatchingCustomerCard()?.codeForCart()
    }

    func updateCart(_ shop: Shop) {
        if shop.id == cart?.shopId {
            self.cart?.updateProducts()
        }
    }

    func reset() {
        cart = nil
    }

}
