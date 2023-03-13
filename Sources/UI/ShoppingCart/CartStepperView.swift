//
//  CartStepperView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

struct BorderedButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray, lineWidth: 0.5)
                )
    }
}

struct CartStepperView: View {
    @ObservedObject var itemModel: CartItemModel
    @EnvironmentObject var cartModel: ShoppingCartViewModel

    @ViewBuilder
    var minusImage: some View {
        Image(systemName: itemModel.quantity == 1 ? "trash" : "minus")
            .foregroundColor(.accentColor)
            .frame(width: 20, height: 20)
    }
    @ViewBuilder
    var plusImage: some View {
        Image(systemName: "plus")
            .foregroundColor(.accentColor)
            .frame(width: 20, height: 20)
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
            
            Text("\(itemModel.quantity)")
                .font(.footnote)
                .fontWeight(.bold)
                .frame(minWidth: 20)

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
        cartModel.increment(item: itemModel.item)
    }
    func minus() {
        cartModel.decrement(item: itemModel.item)
    }
}
