//
//  ShoppingCartView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

public struct ShoppingCartView: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    let compactMode: Bool
    
    init(shoppingCart: ShoppingCart, compactMode: Bool = false) {
        self.cartModel = ShoppingCartViewModel(shoppingCart: shoppingCart)
        self.compactMode = compactMode
    }
    
    @ViewBuilder
    var footer: some View {
        if !compactMode {
            ShoppingCartFooterView(cartModel: cartModel)
        }
    }
    
    public var body: some View {
        if cartModel.numberOfProducts == 0 {
            if !compactMode {
                Text(keyed: "Snabble.Shoppingcart.EmptyState.description")
            }
        } else {
            ShoppingCartItemsView(cartModel: cartModel, footer: footer)
        }
    }
}
