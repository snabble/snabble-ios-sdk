//
//  CartItemAddView.swift
//  
//
//  Created by Uwe Tilemann on 03.11.22.
//

import SnabbleCore
import SwiftUI

public struct CartItemQuantityView: View {
    @ObservedObject var cartItemModel: CartItemModel
   
    @State private var stringValue = ""
    
    var quantity: Int {
        cartItemModel.itemQuantity
    }
    
    @ViewBuilder
    var minusButton: some View {
        if cartItemModel.hasPrice {
            Button(action: {
                cartItemModel.quantityDecrement()
            }) {
                Image(systemName: quantity > 1 ? "minus" : "trash")
                    .font(.title3)
            }
            .frame(width: 44, height: 44)
            .disabled(quantity == 1)
            .background(Color.secondarySystemBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.lightGray, lineWidth: 0.5))
        }
    }
    
    @ViewBuilder
    var plusButton: some View {
        if cartItemModel.hasPrice {
            Button(action: {
                cartItemModel.quantityIncrement()
            }) {
                Image(systemName: "plus")
                    .font(.title3)
            }
            .frame(width: 44, height: 44)
            .background(Color.secondarySystemBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.lightGray, lineWidth: 0.5))
        }
    }

    public var body: some View {
        HStack {
            minusButton
            TextField("", text: $stringValue)
                .multilineTextAlignment(.center)
                .disabled(!cartItemModel.hasPrice)
                .frame(width: 100, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.lightGray, lineWidth: 0.5))
            plusButton
        }
        .onChange(of: quantity) { _ in
            stringValue = cartItemModel.itemQuantityString
        }
        .onAppear {
            stringValue = cartItemModel.itemQuantityString
        }
    }
}

public struct CartItemAddView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var cartItemModel: CartItemModel

    public init(viewModel: CartItemModel) {
        cartItemModel = viewModel
    }
    
    @ViewBuilder
    var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.title3)
        }
    }
    
    @ViewBuilder
    var button: some View {
        let title = cartItemModel.alreadyInCart ? Asset.localizedString(forKey: "Snabble.Scanner.updateCart") : Asset.localizedString(forKey: "Snabble.Scanner.addToCart")

        Button(action: {
            cartItemModel.addToCart()
            presentationMode.wrappedValue.dismiss()
        }) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle())
    }
    @ViewBuilder
    var price: some View {
        if cartItemModel.hasPrice {
            Text(cartItemModel.itemPrice)
        }
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            closeButton
            Text(cartItemModel.itemName)
                .font(.headline)
            price
            CartItemQuantityView(cartItemModel: cartItemModel)
            button
            
            Spacer()
        }
        .padding()
    }
}
