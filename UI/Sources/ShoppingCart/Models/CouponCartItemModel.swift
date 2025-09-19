//
//  CouponCartItemModel.swift
//  
//
//  Created by Uwe Tilemann on 27.03.23.
//

import SwiftUI
import SnabbleCore

open class CouponCartItemModel: CartItemModel, ShoppingCartItemCounting {
    
    public var quantity: Int
    
    let cartCoupon: CartCoupon
    let lineItem: CheckoutInfo.LineItem?
    
    init(cartCoupon: CartCoupon, for lineItem: CheckoutInfo.LineItem?, showImages: Bool = true) {
        self.cartCoupon = cartCoupon
        self.lineItem = lineItem
        self.quantity = 1
        
        super.init(title: cartCoupon.coupon.name, leftDisplay: showImages ? .image : .badge, rightDisplay: .trash, showImages: showImages)
    }
    var subtitle: String {
        return cartCoupon.coupon.description ?? ""
    }
    var isRedeemed: Bool {
        return lineItem?.redeemed == true
    }
}

extension CouponCartItemModel: ShoppingCartItemBadging {
    public var badgeText: String? {
        return "%"
    }
    public var badgeColor: ColorStyle {
        isRedeemed ? .systemRed : .systemGray
    }
}
