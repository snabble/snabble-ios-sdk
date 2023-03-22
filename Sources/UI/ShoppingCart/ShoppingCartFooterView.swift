//
//  ShoppingCartFooterView.swift
//  
//
//  Created by Uwe Tilemann on 22.03.23.
//

import SwiftUI

public struct ShoppingCartFooterView: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    
    @State var total: Int = 0
    @State var regularTotal: Int = 0
 
    public var body: some View {
        HStack(spacing: 0) {
            if cartModel.showImages {
                SwiftUI.Image(systemName: "cart")
                    .cartImageModifier(padding: 10)
                    .padding(.trailing, 10)
            }
            VStack(alignment: .leading, spacing: 8) {
                if total != regularTotal {
                    HStack {
                        Text(cartModel.formatter.format(regularTotal))
                            .strikethrough()
                        Text(cartModel.formatter.format(regularTotal - total) + " " + Asset.localizedString(forKey: "Snabble.Shoppingcart.saved"))
                        
                    }
                    .foregroundColor(.secondary)
                }
                Text(cartModel.formatter.format(total))
                    .font(.headline)
            }
            Spacer()
            Text(cartModel.numberOfProductsString)
        }
        .onAppear {
            updateView()
        }
        .padding(.leading, -10)
        .padding(.trailing, -10)
        .listRowBackground(Color.tertiarySystemGroupedBackground)
    }
    private func updateView() {
        total = cartModel.total
        regularTotal = cartModel.regularTotal
    }
}
