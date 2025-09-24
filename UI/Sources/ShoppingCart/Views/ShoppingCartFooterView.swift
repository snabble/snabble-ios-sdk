//
//  ShoppingCartFooterView.swift
//  
//
//  Created by Uwe Tilemann on 22.03.23.
//

import SwiftUI
import SnabbleAssetProviding

public struct ShoppingCartFooterView: View {
    @Environment(ShoppingCartViewModel.self) var cartModel
    
    @State var total: Int?
    @State var regularTotal: Int?
 
    @ViewBuilder
    var content: some View {
        if let total = total, let regularTotal = regularTotal {
            HStack(spacing: 0) {
                if cartModel.showImages {
                    SwiftUI.Image(systemName: "cart")
                        .cartImageModifier(padding: 10)
                        .padding(.trailing, 10)
                }
                VStack(alignment: .leading, spacing: 8) {
                    if total != regularTotal {
                        HStack {
                            Text(cartModel.regularTotalString)
                                .strikethrough()
                            Text(cartModel.totalDiscountString + " " + Asset.localizedString(forKey: "Snabble.Shoppingcart.saved"))
                            
                        }
                        .foregroundColor(.secondary)
                    }
                    Text(cartModel.totalString)
                        .font(.headline)
                }
                Spacer()
                Text(cartModel.numberOfProductsString)
            }
        } else {
            HStack(spacing: 0) {
                Text("")
            }
        }
    }
    
    public var body: some View {
        content
            .onAppear {
                updateView()
            }
            .padding(.leading, -8)
            .padding(.trailing, -8)
            .listRowBackground(Color.tertiarySystemGroupedBackground)
    }
    
    private func updateView() {
        total = cartModel.total
        regularTotal = cartModel.regularTotal
    }
}
