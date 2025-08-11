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

extension CartItem: Equatable {
    public static func == (lhs: SnabbleCore.CartItem, rhs: SnabbleCore.CartItem) -> Bool {
        lhs.uuid == rhs.uuid &&
        lhs.quantity == rhs.quantity
    }
}
extension CartItem {
    var quantityValue: Int {
        var quantity = effectiveQuantity

        if quantity > ShoppingCart.maxAmount {
            quantity = ShoppingCart.maxAmount
        }
        return quantity
    }
}

extension Shopper {
    public var priceFormatter: PriceFormatter {
        return PriceFormatter(barcodeManager.project)
    }
    public func priceString(for item: CartItem) -> String {
        let formattedPrice = item.priceDisplay(priceFormatter)
        let quantityDisplay = item.quantityDisplay()
        let showQuantity = item.effectiveQuantity > 1 || item.product.deposit != nil
        return (showQuantity ? quantityDisplay + " " : "") + formattedPrice
    }
    
    func quantityValue(for item: CartItem) -> Int {
        item.quantityValue
    }
    
    public func hasPrice(for item: CartItem) -> Bool {
        let product = item.product
        
        // suppress display when price == 0
        var hasPrice = product.price(barcodeManager.shoppingCart.customerCard) != 0
        if item.encodingUnit == .price {
            hasPrice = true
        }
        return hasPrice
    }
}
