//
//  File.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.09.25.
//

import Foundation

import SnabbleCore

extension ShoppingCartViewModel {
    func discountItems(item: CartItem, for lineItems: [CheckoutInfo.LineItem]) -> [ShoppingCartItemDiscount] {

        var discountItems = [ShoppingCartItemDiscount]()
        
        for lineItem in lineItems {
            guard let modifiers = lineItem.priceModifiers else { continue }
            
            for modifier in modifiers {
                let discount = item.discountedPrice(withModifier: modifier, for: lineItem)
                let discountCartItem = ShoppingCartItemDiscount(discount: discount, name: modifier.name, type: .priceModifier)
                discountItems.append(discountCartItem)
            }
        }
        
        let discounts = lineItems.filter { $0.type == .discount }
        let cartDiscountID = shoppingCart.cartDiscountLineItems?.first?.discountID
        
        for discount in discounts {
            if cartDiscountID == nil, let total = discount.totalPrice {
                let discountCartItem = ShoppingCartItemDiscount(discount: total, name: discount.name, type: .discountedProduct)
                discountItems.append(discountCartItem)
            } else if discount.discountID != cartDiscountID, let total = discount.totalPrice {
                let discountCartItem = ShoppingCartItemDiscount(discount: total, name: discount.name, type: .discountedProduct)
                discountItems.append(discountCartItem)
            }
        }
        return discountItems
    }
    
    var totalDiscountItem: CartEntry {
        return CartEntry.discount(totalDiscount)
    }

    var totalDiscount: Int {
        return self.shoppingCart.totalCartDiscount
    }
    
    var totalDiscountDescription: String? {
        return self.shoppingCart.cartDiscountDescription
    }
    
    var totalDiscountString: String {
        formatter.format(totalDiscount)
    }
}
