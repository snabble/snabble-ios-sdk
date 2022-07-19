//
//  ShoppingCartManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.07.22.
//

import Foundation

public protocol ShoppingCartManagerDelegate: AnyObject {
    func shoppingCartManager(_ shoppingCartManager: ShoppingCartManager, customerCardForShop shop: Shop) -> String
    func shoppingCartManager(_ shoppingCartManager: ShoppingCartManager, couponsForShop shop: Shop) -> [Coupon]
}

public final class ShoppingCartManager {
    public static let shared = ShoppingCartManager()

    public weak var delegate: ShoppingCartManagerDelegate?

    public private(set) var cart: ShoppingCart?

    private init() {}

    public func update(with shop: Shop) {
        if shop.id != cart?.shopId {
            let config = CartConfig(shop: shop)
            cart = ShoppingCart(config)
        }
        let coupons = delegate?.shoppingCartManager(self, couponsForShop: shop)
        coupons?.forEach {
            cart?.addCoupon($0)
        }
        cart?.customerCard = delegate?.shoppingCartManager(self, customerCardForShop: shop)
        cart?.updateProducts()
    }

//    func changeCart(shop: Shop) {
//        let config = CartConfig(shop: shop)
//        cart = ShoppingCart(config)
//        cart?.updateProducts()
//    }

//    func updateCustomerCard(_ customerCard: Any) {
//        cart?.customerCard = customerCard
//        self.cart?.customerCard = Snabble.shared.project(for: shop.projectId)?.getMatchingCustomerCard()?.codeForCart()
//    }

//    func updateCart(_ shop: Shop) {
//        if shop.id == cart?.shopId {
//            self.cart?.updateProducts()
//        }
//    }

    public func reset() {
        cart = nil
    }

}
