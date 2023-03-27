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
    @ObservedObject var itemModel: ProductItemModel
    @EnvironmentObject var cartModel: ShoppingCartViewModel

    @ViewBuilder
    var minusImage: some View {
        Image(systemName: itemModel.quantity == 1 ? "trash" : "minus")
            .foregroundColor(.accentColor)
            .frame(width: 22, height: 22)
    }
    @ViewBuilder
    var plusImage: some View {
        Image(systemName: "plus")
            .foregroundColor(.accentColor)
            .frame(width: 22, height: 22)
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
        cartModel.increment(itemModel: itemModel)
    }
    func minus() {
        cartModel.decrement(itemModel: itemModel)
    }
}
