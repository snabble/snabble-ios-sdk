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
import SnabbleComponents

extension ShoppingCartViewModel {
    func updateQuantity(_ string: Binding<String>, for cartEntry: CartEntry) {
        guard let quantity = Int(string.wrappedValue), quantity > 0 else {
            string.wrappedValue = "\(self.quantity(for: cartEntry))"
            return
        }
        self.updateQuantity(quantity, for: cartEntry)
    }
}

struct CartWeightView: View {
    @SwiftUI.Environment(\.projectTrait) private var project

    let cartEntry: CartEntry
    let editable: Bool
    @Environment(ShoppingCartViewModel.self) var cartModel
    @ScaledMetric var scale: CGFloat = 1

    @State private var weightText: String = ""

    init(cartEntry: CartEntry, editable: Bool = false) {
        self.cartEntry = cartEntry
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
                cartModel.updateQuantity($weightText, for: cartEntry)
            },
                           content: {
                Text("")
            })
            .frame(maxWidth: 80 * scale, maxHeight: 26 * scale)
        } else if let value = cartModel.quantityText(for: cartEntry) {
            Text(value)
                .font(Font.system(size: 13 * scale, weight: .semibold))
        }
    }

    var body: some View {
        HStack(spacing: 8 * scale) {
            valueView

            Text(cartModel.unitString(for: cartEntry) ?? "")
                .font(Font.system(size: 13 * scale, weight: .semibold))

            Button( action: {
                withAnimation {
                    cartModel.trash(cartEntry: cartEntry)
                }
            }) {
                minusImage
            }
            .buttonStyle(BorderedButtonStyle())
        }
        .onAppear {
            weightText = "\(cartModel.quantity(for: cartEntry))"
        }
    }
}
