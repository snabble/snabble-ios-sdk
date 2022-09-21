//
//  ShoppingListDelegate.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import SnabbleCore

public protocol ShoppingListDelegate: AnalyticsDelegate {
    func shouldMarkItemDone(in: ShoppingList, sku: String) -> Int?
}
