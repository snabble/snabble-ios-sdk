//
//  Core.swift
//  
//
//  Created by Uwe Tilemann on 21.12.22.
//

import Foundation

public typealias CoreProviding = ShoppingCartMerging

public enum Core {
    /// Reference to the implementation of the `CoreProviding` implementation
    nonisolated(unsafe) public static weak var provider: CoreProviding?

    /// Reference to the current domain
    nonisolated(unsafe) public static var domain: Any?

    // MARK: - ShoppingCartMerging
    public static func shoppingCart(_ shoppingCart: ShoppingCart, shouldMergeItem item: CartItem, domain: Any? = domain) -> Bool? {
        return provider?.shoppingCart(shoppingCart, shouldMergeItem: item, domain: domain)
    }
}
