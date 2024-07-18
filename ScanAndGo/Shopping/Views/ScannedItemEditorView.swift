//
//  ScannerCartItemView.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

extension BarcodeManager {
    public var coupons: [CouponItem] {
        project.manualCoupons.map { CouponItem(coupon: $0) }
    }
}

public struct CouponItem: Equatable, Swift.Identifiable {
    public let id = UUID()
    public let coupon: Coupon
}

struct DiscountMenu: View {
    var coupons: [CouponItem] = []
    @Binding var selection: CouponItem?

    @State var title: String = Asset.localizedString(forKey: "Snabble.addDiscount")
    
    var body: some View {
        Menu(title) {
            ForEach(coupons, id: \.id) { item in
                Button(item.coupon.name, action: { useCoupon(item) })
           }
        }
        .disabled(coupons.isEmpty)
    }
    private func useCoupon(_ item: CouponItem) {
        title = item.coupon.name
        selection = item
    }
}

struct QuantityMinusButton: View {
    @Binding var quantity: Int
    
    var body: some View {
        Button {
            quantity -= 1
        } label: {
            SwiftUI.Image(systemName: quantity > 1 ? "minus" : "trash")
                .resizable()
                .scaledToFit()
                .padding(12)
                .frame(width: 44, height: 44)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .strokeBorder(Color.secondary, lineWidth: 1)
        )
    }
}

struct QuantityPlusButton: View {
    @Binding var quantity: Int
    
    var body: some View {
        Button {
            quantity += 1
        } label: {
            SwiftUI.Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .padding(12)
                .frame(width: 44, height: 44)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .strokeBorder(Color.secondary, lineWidth: 1)
        )
    }
}

struct ScannerQuantityView: View {
    @Binding var quantity: Int
    let canEdit: Bool
    
    @State private var quantityString: String = "0"
    
    var body: some View {
        HStack {
            Spacer()
            QuantityMinusButton(quantity: $quantity)
                .disabled(!(quantity > 1))
            
            TextField("Quantity", text: $quantityString)
                .font(.title3)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 100, height: 44)
                .background(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary, lineWidth: 1)
                )
                .disabled(!canEdit)
            
            QuantityPlusButton(quantity: $quantity)
                .disabled(!(quantity < ShoppingCart.maxAmount))

            Spacer()
        }
        .onChange(of: quantity) { _, _ in
            quantityString = String(quantity)
        }
        .task {
            quantityString = String(quantity)
        }
    }
}

struct ScannerCartItemView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @ObservedObject var model: Shopper
    
    let scannedItem: BarcodeManager.ScannedItem
    let alreadyInCart: Bool
    let onAction: (_: CartItem?) -> Void
    
    @State private var cartItem: CartItem
    @State private var canAddToCart: Bool = false
    @State private var strikePrice: String?
    @State private var price: String?
    @State private var quantity: Int
    @State private var selectedCoupon: CouponItem?
    
    init(model: Shopper,
         scannedItem: BarcodeManager.ScannedItem,
         onAction: @escaping (_: CartItem?) -> Void
    ) {
        self.model = model
        self.scannedItem = scannedItem
        
        let result = model.cartItem(for: scannedItem)
        self.cartItem = result.cartItem
        self.quantity = result.cartItem.quantity
        self.alreadyInCart = result.alreadyInCart
        
        self.onAction = onAction
        
        self.strikePrice = model.strikePrice(for: scannedItem)
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 6) {
                Button(action: {
                    onAction(nil)
                    dismiss()
                }) {
                    SwiftUI.Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.vertical)
                
                if let subtitle = cartItem.product.subtitle {
                    Text(subtitle)
                }
                Text(scannedItem.product.name)
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .padding(.horizontal)
                
                if let strikePrice {
                    Text("~~\(strikePrice)~~")
                }
                
                if let price {
                    Text(price)
                }
                if !model.barcodeManager.project.manualCoupons.isEmpty {
                    DiscountMenu(coupons: model.barcodeManager.coupons, selection: $selectedCoupon)
                }
                
                ScannerQuantityView(quantity: $quantity, canEdit: true /*cartItem.editable*/)
                    .onChange(of: quantity) { _, newValue in
                        self.cartItem.setQuantity(newValue)
                        self.price = model.priceString(for: self.cartItem)
                    }
                    .padding(.top)

                let title = alreadyInCart ? Asset.localizedString(forKey: "Snabble.Scanner.updateCart") : Asset.localizedString(forKey: "Snabble.Scanner.addToCart")
                
                PrimaryButtonView(title: title, onAction: {
                    onAction(self.cartItem)
                    dismiss()
               })
                .padding()
            }
            .task {
                self.price = model.priceString(for: cartItem)
            }
            .onChange(of: cartItem) { _, newItem in
                self.cartItem = newItem
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            .padding()
        }
    }
}

struct ScannedItemEditorView: View {
    @SwiftUI.Environment(\.keyboardHeight) var keyboardHeight
    @ObservedObject var model: Shopper
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            if let scannedItem = model.scannedItem {
                Spacer()
                ScannerCartItemView(
                    model: model,
                    scannedItem: scannedItem,
                    onAction: { cartItem in
                        self.updateCartItem(cartItem)
                    })
           } else {
                Text("No scanned item!")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, (keyboardHeight > 0 ? keyboardHeight + 80 : 150))
   }
    func updateCartItem(_ cartItem: CartItem?) {
        if let cartItem {
            model.updateCartItem(cartItem)
        }
        withAnimation {
            isPresented = false
        }
    }
}
