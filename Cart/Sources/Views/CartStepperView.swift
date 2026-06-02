//
//  CartStepperView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore
import SnabbleComponents

struct BorderedButtonStyle: ButtonStyle {
    let radius: CGFloat

    init(radius: CGFloat = 6) {
        self.radius = radius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(radius)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color.gray, lineWidth: 0.5)
                )
    }
}

struct CartStepperView: View {
    @SwiftUI.Environment(\.projectTrait) private var project

    var itemModel: ProductItemModel
    @Environment(ShoppingCartViewModel.self) var cartModel
    @ScaledMetric var scale: CGFloat = 1
    
    private var currentQuantity: Int {
        // Find the current item in the cart to get the latest quantity
        if let cartEntry = cartModel.items.first(where: { entry in
            if case .cartItem(let item, _) = entry {
                return item.uuid == itemModel.item.uuid
            }
            return false
        }), case .cartItem(let item, _) = cartEntry {
            return item.quantity
        }
        return itemModel.item.quantity
    }

    @ViewBuilder
    var minusImage: some View {
        Image(systemName: currentQuantity == 1 ? "trash" : "minus")
            .foregroundColor(.projectPrimary())
            .frame(width: 22 * scale, height: 22 * scale)
    }
    @ViewBuilder
    var plusImage: some View {
        Image(systemName: "plus")
            .foregroundColor(.projectPrimary())
            .frame(width: 22 * scale, height: 22 * scale)
    }

    var body: some View {
        HStack(spacing: 4) {
            
            Button( action: {
                withAnimation {
                    self.minus()
                }
            }) {
                minusImage
            }
            .buttonStyle(BorderedButtonStyle())

            Text("\(currentQuantity)")
                .font(.footnote)
                .fontWeight(.bold)
                .frame(minWidth: 20 * scale)
                .id(currentQuantity) // Force view update when quantity changes

            Button( action: {
                withAnimation {
                    self.plus()
                }
            }) {
                plusImage
            }
            .buttonStyle(BorderedButtonStyle())
        }
    }
    func plus() {
        cartModel.increment(itemModel: itemModel)
    }
    func minus() {
        cartModel.decrement(itemModel: itemModel)
    }
}
