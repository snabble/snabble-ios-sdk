//
//  CartEntry.swift
//  
//
//  Created by Uwe Tilemann on 28.03.23.
//

import SnabbleCore

extension CartEntry: Equatable {
    public static func == (lhs: CartEntry, rhs: CartEntry) -> Bool {
        lhs.id == rhs.id
    }
}

public enum CartEntry: Swift.Identifiable {
    public var id: String {
        switch self {
        case .cartItem(let cartItem, _):
            return cartItem.uuid
            
        case .coupon(let cartCoupon, _):
            return cartCoupon.uuid
            
        case .voucher(let voucher, _):
            return voucher.uuid

            // stuff we get from the backend isn't
        case .lineItem(let lineItem, _):
            return lineItem.id
            
        case .discount(let discount):
            return String(discount)
            
        case .giveaway(let lineItem):
            return lineItem.id
            
        }
    }
    
    // our main item and any additional line items referring to it
    case cartItem(CartItem, [CheckoutInfo.LineItem])

    // a user-added coupon, plus the backend info for it
    case coupon(CartCoupon, CheckoutInfo.LineItem?)
    
    // a user-added coupon, plus the backend info for it
    case voucher(CartVoucher, CheckoutInfo.LineItem?)

    // a new main item from the backend, plus its additional items.
    case lineItem(CheckoutInfo.LineItem, [CheckoutInfo.LineItem])

    // a giveaway
    case giveaway(CheckoutInfo.LineItem)

    // sums up the total discounts
    case discount(Int)
}
