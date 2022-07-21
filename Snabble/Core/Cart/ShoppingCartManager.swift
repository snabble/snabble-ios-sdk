//
//  ShoppingCartManager.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.07.22.
//

import Foundation

public protocol ShoppingCartManagerDelegate: AnyObject {
    func shoppingCartManager(_ shoppingCartManager: ShoppingCartManager, customerCardForShop shop: Shop) -> String?
}

public final class ShoppingCartManager {
    public weak var delegate: ShoppingCartManagerDelegate?

    public private(set) var shop: Shop?
    public private(set) var shoppingCart: ShoppingCart?

    public private(set) lazy var couponManager: CouponManager = Snabble.shared.couponManager

    init() {}

    @discardableResult
    public func shoppingCart(for shop: Shop) -> ShoppingCart {
        if let shoppingCart = shoppingCart, self.shop == shop, shop.id == shoppingCart.shopId {
            return shoppingCart
        } else {
            let config = CartConfig(shop: shop)
            let shoppingCart = ShoppingCart(with: config)

            couponManager.activated(for: shop.projectId)?.forEach {
                shoppingCart.addCoupon($0)
            }
            shoppingCart.customerCard = delegate?.shoppingCartManager(self, customerCardForShop: shop)
            shoppingCart.updateProducts()
            self.shop = shop
            self.shoppingCart = shoppingCart
            return shoppingCart
        }
    }
}
