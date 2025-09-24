//
//  ShoppingManager+CartItem.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 23.06.24.
//

import Foundation

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

//extension CartItem: Equatable {
//    public static func == (lhs: SnabbleCore.CartItem, rhs: SnabbleCore.CartItem) -> Bool {
//        lhs.uuid == rhs.uuid &&
//        lhs.quantity == rhs.quantity
//    }
//}

extension CartItem {
    var quantityValue: Int {
        var quantity = effectiveQuantity

        if quantity > ShoppingCart.maxAmount {
            quantity = ShoppingCart.maxAmount
        }
        return quantity
    }
}
