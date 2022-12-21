//
//  ShoppingCartProviding.swift
//  
//
//  Created by Uwe Tilemann on 21.12.22.
//

import Foundation

public protocol ShoppingCartMerging: AnyObject {
    /// Give a hosting app the ability the prevent shopping item to be merged for a given `domain`
    ///
    /// Make sure only return `false` if the given item should not be merged
    /// - Parameters:
    ///   - shoppingCart: The `ShoppingCart` instance asking to merge the given item with the items in the shopping cart.
    ///   - item: `CartItem` the shopping cart wants to merge
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: A `Bool` or nil if that indicates if the shopping cart logic to merge an item should be applied.
    ///  If the hosting app returns `false` the item will be not merged.
    func shoppingCart(_ shoppingCart: ShoppingCart, shouldMergeItem item: CartItem, domain: Any?) -> Bool?
}
