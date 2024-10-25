//
//  ScannerCartItemView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
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
    
    enum FocusedField: Hashable {
        case quantity
    }
    @FocusState var focusedField: FocusedField?
    
    var body: some View {
        HStack {
            Spacer()
            QuantityMinusButton(quantity: $quantity)
                .disabled(!(quantity > 1))
            
            TextField(Asset.localizedString(forKey: "Snabble.Shoppingcart.Accessibility.quantity"), text: $quantityString)
                .font(.title3)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 100, height: 44)
                .background(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary, lineWidth: 1)
                )
                .disabled(!canEdit)
                .focused($focusedField, equals: .quantity)
            
            QuantityPlusButton(quantity: $quantity)
                .disabled(!(quantity < ShoppingCart.maxAmount))
            
            Spacer()
        }
        .task {
            quantityString = String(quantity)
        }
        .onAppear {
            if canEdit {
                focusedField = .quantity
            }
        }
        .onChange(of: quantityString) {
            if let intValue = Int(quantityString) {
                self.quantity = intValue
            }
        }
        .onChange(of: quantity) {
            quantityString = String(quantity)
        }
    }
}

struct ScannerCartItemView: View {
    @ObservedObject var model: Shopper
    
    let scannedItem: BarcodeManager.ScannedItem
    let onDismiss: () -> Void
    let onAdd: (_ cartItem: CartItem) -> Void
    let alreadyInCart: Bool
    
    @State private var cartItem: CartItem
    @State private var quantity: Int
    
    @State private var disableCheckout: Bool = true
    @State private var strikePrice: String?
    @State private var price: String?
    @State private var selectedCoupon: CouponItem?
    
    init(model: Shopper,
         scannedItem: BarcodeManager.ScannedItem,
         onDismiss: @escaping () -> Void,
         onAdd: @escaping (_ cartItem: CartItem) -> Void
    ) {
        self.model = model
        self.scannedItem = scannedItem
        self.onAdd = onAdd
        self.onDismiss = onDismiss
        
        let result = model.cartItem(for: scannedItem)
        var cartItem = result.cartItem
        
        self.alreadyInCart = result.alreadyInCart
        
        cartItem.setQuantity(cartItem.quantity > 0 ? cartItem.quantity : 1)
        self._cartItem = State(initialValue: cartItem)
        self._quantity = State(initialValue: cartItem.quantity)
        
        self.price = model.priceString(for: cartItem)
        self.strikePrice = model.strikePrice(for: scannedItem)
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 6) {
                Button(action: {
                    onDismiss()
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
                
                ScannerQuantityView(quantity: $quantity, canEdit: cartItem.editable)
                    .onChange(of: quantity) { _, newValue in
                        self.cartItem.setQuantity(newValue)
                        self.price = model.priceString(for: self.cartItem)
                    }
                    .padding(.top)
                
                let title = alreadyInCart ? Asset.localizedString(forKey: "Snabble.Scanner.updateCart") : Asset.localizedString(forKey: "Snabble.Scanner.addToCart")
                
                PrimaryButtonView(title: title, disabled: $disableCheckout, onAction: {
                    onAdd(cartItem)
                })
                .padding()
            }
            .task {
                self.price = model.priceString(for: cartItem)
                self.quantity = cartItem.quantity > 0 ? cartItem.quantity : 1
                self.disableCheckout = !canAddItem(cartItem)
            }
            .onChange(of: cartItem) { _, newItem in
                self.cartItem = newItem
                self.disableCheckout = !canAddItem(newItem)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            .padding()
        }
    }
    func canAddItem(_ cartItem: CartItem) -> Bool {
        if cartItem.editable {
            return cartItem.quantity > 0
        }
        return true
    }
}

struct ScannedItemEditorView: View {
    @SwiftUI.Environment(\.keyboardHeight) var keyboardHeight
    @ObservedObject var model: Shopper
    var onDismiss: () -> Void
    
    var body: some View {
        VStack {
            if let scannedItem = model.scannedItem {
                Spacer()
                ScannerCartItemView(
                    model: model,
                    scannedItem: scannedItem,
                    onDismiss: onDismiss,
                    onAdd: { cartItem in
                        updateCartItem(cartItem)
                    })
            }
        }
        .padding(.bottom, (keyboardHeight > 0 ? 20 : 150))
    }
    
    private func updateCartItem(_ cartItem: CartItem) {
        model.updateCartItem(cartItem)
        onDismiss()
    }
}
