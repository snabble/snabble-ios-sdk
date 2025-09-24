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
    @Environment(ShoppingCartViewModel.self) var cartModel

    let cartEntry: CartEntry

    @ScaledMetric var scale: CGFloat = 1

    @ViewBuilder
    var minusImage: some View {
        Image(systemName: cartModel.quantity(for: cartEntry) == 1 ? "trash" : "minus")
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

            Text("\(cartModel.quantity(for: cartEntry))")
                .font(.footnote)
                .fontWeight(.bold)
                .frame(minWidth: 20 * scale)

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
        cartModel.increment(cartEntry: cartEntry)
    }
    func minus() {
        cartModel.decrement(cartEntry: cartEntry)
    }
}
