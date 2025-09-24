//
//  File.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.09.25.
//

import Foundation

import SnabbleCore

// MARK: - CartEntry Actions
extension ShoppingCartViewModel {
    func increment(cartEntry: CartEntry) {
        guard case .cartItem(let item, _) = cartEntry else { return }

        print("+ \(item.product.name)")
        if item.quantity < ShoppingCart.maxAmount {
            let newQuantity = item.quantity + 1
            self.shoppingCart.setQuantity(newQuantity, for: item)
            NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        }
    }

    func decrement(cartEntry: CartEntry) {
        guard case .cartItem(let item, _) = cartEntry else { return }

        print("- \(item.product.name)")
        if item.quantity > 1 {
            let newQuantity = item.quantity - 1
            self.shoppingCart.setQuantity(newQuantity, for: item)
            NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        } else {
            trash(cartEntry: cartEntry)
        }
    }

    func trash(cartEntry: CartEntry) {
        guard let index = items.firstIndex(where: { $0.id == cartEntry.id }) else { return }
        trash(at: IndexSet([index]))
    }

    func updateQuantity(_ newQuantity: Int, for cartEntry: CartEntry) {
        guard case .cartItem(let item, _) = cartEntry else { return }

        if newQuantity > 0 {
            self.shoppingCart.setQuantity(newQuantity, for: item)
            NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        }
    }
}
