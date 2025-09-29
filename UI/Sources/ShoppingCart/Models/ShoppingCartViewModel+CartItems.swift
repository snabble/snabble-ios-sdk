//
//  File.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.09.25.
//

import Foundation

import SnabbleCore

extension ShoppingCartViewModel {

    var cartItems: [(cartItem: CartItem, lineItems: [CheckoutInfo.LineItem])] {
        return internalCartItems.cartItems
    }

    // find all line items that refer to our own cart items
    private var internalCartItems: (cartItems: [(cartItem: CartItem, lineItems: [CheckoutInfo.LineItem])], pendingLookups: [PendingLookup]) {
        var cartItems = [(cartItem: CartItem, lineItems: [CheckoutInfo.LineItem])]()
        var pendingLookups = [PendingLookup]()

        // find all line items that refer to our own cart items
        for (index, cartItem) in self.shoppingCart.items.enumerated() {
            if let lineItems = self.shoppingCart.backendCartInfo?.lineItems {
                let items = lineItems.filter { $0.id == cartItem.uuid || $0.refersTo == cartItem.uuid }

                // if we have a single lineItem that updates this entry with another SKU,
                // propagate the change to the shopping cart
                if let lineItem = items.first, items.count == 1, let sku = lineItem.sku, sku != cartItem.product.sku {
                    let productProvider = Snabble.shared.productProvider(for: SnabbleCI.project)
                    let product = productProvider.productBy(sku: sku, shopId: self.shoppingCart.shopId)
                    if let product = product, let replacement = CartItem(replacing: cartItem, product, self.shoppingCart.shopId, lineItem) {
                        self.shoppingCart.replaceItem(at: index, with: replacement)
                    } else {
                        pendingLookups.append(PendingLookup(index, cartItem, lineItem))
                    }
                }
                cartItems.append((cartItem, items))
            } else {
                cartItems.append((cartItem, []))
            }
        }
        return (cartItems, pendingLookups)
    }

    private var pendingLookups: [PendingLookup] {
        return internalCartItems.pendingLookups
    }
    
    func checkPendingLookups() {
        let pendingLookups = self.pendingLookups
        // perform any pending lookups
        if !pendingLookups.isEmpty {
            self.performPendingLookups(pendingLookups, self.shoppingCart.lastSaved)
        }
    }
}

extension ShoppingCartViewModel {
    struct PendingLookup {
        let index: Int
        let cartItem: CartItem
        let lineItem: CheckoutInfo.LineItem

        init(_ index: Int, _ cartItem: CartItem, _ lineItem: CheckoutInfo.LineItem) {
            self.index = index
            self.cartItem = cartItem
            self.lineItem = lineItem
        }
    }

    private func performPendingLookups(_ lookups: [PendingLookup], _ lastSaved: Date?) {
        let group = DispatchGroup()

        nonisolated(unsafe) var replacements = [(Int, CartItem?)]()
        let mutex = Mutex()

        let productProvider = Snabble.shared.productProvider(for: SnabbleCI.project)
        for lookup in lookups {
            guard let sku = lookup.lineItem.sku else {
                continue
            }

            group.enter()

            productProvider.productBy(sku: sku, shopId: self.shoppingCart.shopId) { result in
                switch result {
                case .failure(let error):
                    Log.error("error in pending lookup for \(sku): \(error)")
                case .success(let product):
                    let replacement = CartItem(replacing: lookup.cartItem, product, self.shoppingCart.shopId, lookup.lineItem)
                    mutex.lock()
                    replacements.append((lookup.index, replacement))
                    mutex.unlock()
                }
                group.leave()
            }
        }

        // when all lookups are finished:
        group.notify(queue: DispatchQueue.main) {
            guard !replacements.isEmpty, self.shoppingCart.lastSaved == lastSaved else {
                Log.warn("no replacements, or cart was modified during retrieval")
                return
            }

            for (index, item) in replacements {
                if let item = item {
                    self.shoppingCart.replaceItem(at: index, with: item)
                } else {
                    Log.warn("no replacement for item #\(index) found")
                }
            }
        }
    }
}
