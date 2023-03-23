//
//  CouponItemView.swift
//  
//
//  Created by Uwe Tilemann on 22.03.23.
//

import SwiftUI
import SnabbleCore

open class CouponCartItemModel: CartItemModel, ShoppingCartItemCounting {
   
    @Published public var quantity: Int
    
    let cartCoupon: CartCoupon
    let lineItem: CheckoutInfo.LineItem?

    init(cartCoupon: CartCoupon, for lineItem: CheckoutInfo.LineItem?, showImages: Bool = true) {
        self.cartCoupon = cartCoupon
        self.lineItem = lineItem
        self.quantity = 1
        
        super.init(title: cartCoupon.coupon.name, leftDisplay: showImages ? .image : .badge, rightDisplay: .trash)
        
        if showImages {
            if let icon: UIImage = Asset.image(named: "SnabbleSDK/icon-percent") {
                self.image = SwiftUI.Image(uiImage: icon.recolored(with: isRedeemed ? .label : .systemGray))
            }
        }
    }
    
    var isRedeemed: Bool {
        return lineItem?.redeemed == true
    }
    var badgeText: String? {
        return "%"
    }
}

struct CouponItemView: View {
    @ObservedObject var itemModel: CouponCartItemModel
    
    var body: some View {
        Text(itemModel.title)
    }
}
