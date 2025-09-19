//
//  ShoppingCartViewModel+Coupons.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.09.25.
//

import Foundation

import SnabbleCore

extension ShoppingCartViewModel {
    var couponItems: [CartEntry] {
        var items = [CartEntry]()
        
        // all coupons
        for coupon in self.coupons {
            let item = CartEntry.coupon(coupon.cartCoupon, coupon.lineItem)
            items.append(item)
        }
        return items
    }
    
    // all coupons
    var coupons: [(cartCoupon: CartCoupon, lineItem: CheckoutInfo.LineItem?)] {
        var coupons = [(cartCoupon: CartCoupon, lineItem: CheckoutInfo.LineItem?)]()

        for coupon in self.shoppingCart.coupons {
            let couponItem = self.shoppingCart.backendCartInfo?.lineItems.filter { $0.couponID == coupon.coupon.id }.first

            coupons.append((coupon, couponItem))
        }
        return coupons
    }
}
