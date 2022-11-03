//
//  ProductAddView.swift
//  
//
//  Created by Uwe Tilemann on 03.11.22.
//

import SnabbleCore
import SwiftUI
import GRDBQuery

public struct ProductAddView: View {
    @EnvironmentStateObject var model: ProductModel
    @Environment(\.presentationMode) var presentationMode
    var product: Product
//    @StateObject private var cartItemModel: CartItemModel?
    
    public init(viewModel: ProductModel, product: Product) {
        _model = EnvironmentStateObject { _ in
            viewModel
        }
        self.product = product
//        self.cartItemModel = CartItemModel(shop: viewModel.shop, scannedProduct: <#T##ScannedProduct#>, scannedCode: <#T##String#>)
    }
    
    @ViewBuilder
    var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.title3)
                .padding([.top, .bottom], 12)
        }
    }
    
    @ViewBuilder
    var button: some View {
        Button(action: {
            model.productActionPublisher.send(product)
        }) {
            Text("Add to cart")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AccentButtonStyle())
    }
    @ViewBuilder
    var price: some View {
        if let product = model.scannedProduct {
            Text("\(product.product.listPrice)")
        }
    }
    
    public var body: some View {
        VStack {
            closeButton
            
            Text(product.name)
                .font(.headline)
            
            price
            button
            
            Spacer()
        }
        .padding()
        .onAppear {
            _ = model.scannedProduct(for: product)
        }
    }
}
