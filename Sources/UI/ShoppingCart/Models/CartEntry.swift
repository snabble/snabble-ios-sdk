//
//  CartEntry.swift
//  
//
//  Created by Uwe Tilemann on 28.03.23.
//

import SnabbleCore

enum CartEntry: Swift.Identifiable {
    var id: String {
        switch self {
        case .cartItem(let cartItem, _):
            return cartItem.uuid
            
        case .coupon(let cartCoupon, _):
            return cartCoupon.uuid
            
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

    // a new main item from the backend, plus its additional items.
    case lineItem(CheckoutInfo.LineItem, [CheckoutInfo.LineItem])

    // a giveaway
    case giveaway(CheckoutInfo.LineItem)

    // sums up the total discounts
    case discount(Int)
    
    var canEdit: Bool {
        switch self {
            // user stuff is editable
        case .cartItem: return true
        case .coupon: return true
            // stuff we get from the backend isn't
        case .lineItem: return false
        case .discount: return false
        case .giveaway: return false
        }
    }
    static func rowFor(item: CartItem, in array: [CartEntry]) -> Int? {
        return array.firstIndex(where: { $0.id == item.uuid })
    }
}
