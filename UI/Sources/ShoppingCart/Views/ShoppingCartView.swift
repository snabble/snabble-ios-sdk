//
//  ShoppingCartView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

public struct ShoppingCartView: View {
    @Environment(ShoppingCartViewModel.self) var cartModel
    let compactMode: Bool
    let listMode: Bool

    public init(compactMode: Bool = false,
                listMode: Bool = true) {
        self.compactMode = compactMode
        self.listMode = listMode
    }

    // Environment-based approach: ShoppingCartViewModel should be provided via .environment()
    // If you need to create a cartModel from ShoppingCart, do it outside and inject via environment

    @ViewBuilder
    var footer: some View {
        if !compactMode {
            ShoppingCartFooterView()
        }
    }
    
    public var body: some View {
        if cartModel.cartIsEmpty {
            if !compactMode {
                Text(keyed: "Snabble.Shoppingcart.EmptyState.description")
            }
        } else {
            ShoppingCartItemsView(footer: footer, asList: listMode)
        }
    }
}
