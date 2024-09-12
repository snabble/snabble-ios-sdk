//
//  CartWeightView.swift
//  
//
//  Created by Uwe Tilemann on 24.03.23.
//

import SwiftUI
import SnabbleCore
import Combine
import SnabbleAssetProviding

extension ShoppingCartViewModel {
    func updateQuantity(_ string: Binding<String>, for itemModel: ProductItemModel) {
        guard let index = cartIndex(for: itemModel) else {
            return
        }
        guard let quantity = Int(string.wrappedValue), quantity > 0 else {
            string.wrappedValue = "\(itemModel.quantity)"
            return
        }
        self.updateQuantity(quantity, at: index)
    }
}

struct CartWeightView: View {
    @ObservedObject var itemModel: ProductItemModel
    let editable: Bool
    @EnvironmentObject var cartModel: ShoppingCartViewModel
    @ScaledMetric var scale: CGFloat = 1

    @State private var weightText: String = ""
    
    init(itemModel: ProductItemModel, editable: Bool = false) {
        self.itemModel = itemModel
        self.editable = editable
    }
    
    @ViewBuilder
    var minusImage: some View {
        Image(systemName: "trash")
            .foregroundColor(.projectPrimary())
            .frame(width: 22 * scale, height: 22 * scale)
    }
    
    @ViewBuilder
    var valueView: some View {
        if editable {
            UIKitTextField("",
                           text: $weightText,
                           keyboardType: .numberPad,
                           textAlignment: .right,
                           tag: ShoppingCart.textFieldMagic,
                           font: UIFont.systemFont(ofSize: 13 * scale, weight: .semibold),
                           onSubmit: {
                cartModel.updateQuantity($weightText, for: itemModel)
            },
                           content: {
                Text("")
            })
            .frame(maxWidth: 80 * scale, maxHeight: 26 * scale)
        } else if let value = itemModel.quantityText {
            Text(value)
                .font(Font.system(size: 13 * scale, weight: .semibold))
        }
    }

    var body: some View {
        HStack(spacing: 8 * scale) {
            valueView
            
            Text(itemModel.unitString ?? "")
                .font(Font.system(size: 13 * scale, weight: .semibold))
                
            Button( action: {
                withAnimation {
                    cartModel.trash(itemModel: itemModel)
                }
            }) {
                minusImage
            }
            .buttonStyle(BorderedButtonStyle())
        }
        .onAppear {
            weightText = "\(itemModel.quantity)"
        }
    }
}
