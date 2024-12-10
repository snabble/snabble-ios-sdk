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
    let listMode: Bool
    
    public init(cartModel: ShoppingCartViewModel, 
                compactMode: Bool = false,
                listMode: Bool = true) {
        self.cartModel = cartModel
        self.compactMode = compactMode
        self.listMode = listMode
    }

    public init(shoppingCart: ShoppingCart, 
                compactMode: Bool = false,
                listMode: Bool = true) {
        self.cartModel = ShoppingCartViewModel(shoppingCart: shoppingCart)
        self.compactMode = compactMode
        self.listMode = listMode
    }

    @ViewBuilder
    var footer: some View {
        if !compactMode {
            ShoppingCartFooterView(cartModel: cartModel)
        }
    }
    
    public var body: some View {
        if cartModel.cartIsEmpty {
            if !compactMode {
                Text(keyed: "Snabble.Shoppingcart.EmptyState.description")
            }
        } else {
            ShoppingCartItemsView(cartModel: cartModel, footer: footer, asList: listMode)
        }
    }
}
