//
//  ShoppingCartView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

public struct ShoppingCartView: View {
    @Bindable var cartModel: ShoppingCartViewModel
    let compactMode: Bool
    var onPreviewRowHeight: ((Int, CGFloat) -> Void)?

    public init(cartModel: ShoppingCartViewModel,
                compactMode: Bool = false,
                onPreviewRowHeight: ((Int, CGFloat) -> Void)? = nil
    ) {
        self.cartModel = cartModel
        self.compactMode = compactMode
        self.onPreviewRowHeight = onPreviewRowHeight
    }

    public init(shoppingCart: ShoppingCart,
                compactMode: Bool = false,
                onPreviewRowHeight: ((Int, CGFloat) -> Void)? = nil
    ) {
        self.cartModel = ShoppingCartViewModel(shoppingCart: shoppingCart)
        self.compactMode = compactMode
        self.onPreviewRowHeight = onPreviewRowHeight
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
            ShoppingCartItemsView(cartModel: cartModel, footer: footer, onPreviewRowHeight: onPreviewRowHeight)
                .onChange(of: cartModel.items) {
                    print("ShoppingCartView: cartModel.items did change")
                }
        }
    }
}
