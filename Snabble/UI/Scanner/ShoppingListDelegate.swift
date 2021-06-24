//
//  ShoppingListDelegate.swift
//  Snabble
//
//  Created by Gereon Steffens on 25.06.21.
//

import Foundation

public protocol ShoppingListDelegate: AnalyticsDelegate {
    func shouldMarkItemDone(in: ShoppingList, sku: String) -> Int?
}
