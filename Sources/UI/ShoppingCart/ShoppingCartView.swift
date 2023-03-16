//
//  ShoppingCartView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

struct CartRowView: View {
    var item: CartTableEntry

    @ViewBuilder
    var itemView: some View {
        switch item {
        case .cartItem(let item, let lineItems):
            CartItemView(item: item, for: lineItems)
//        case .coupon(let coupon, let lineItem):
//            CouponItemView(coupon, for: lineItem)
//
//        case .lineItem(let item, let lineItems):
//            LineItemView(item, for: lineItems)
        case .discount(let amount):
            DiscountView(amount: amount)
//        case .giveaway(let lineItem):
//            GiveawayView(for: lineItem)
        default:
            EmptyView()
        }
    }
    var body: some View {
        itemView
//        HStack(spacing: 0) {
//            image
//            VStack(alignment: .leading) {
//                Text(item.name)
//                    .font(.subheadline)
//                price
//            }
//            discount
//            Spacer()
//            CartStepper(item: item)
//        }
    }
}

public struct ShoppingCartItemsView: View {
    @ObservedObject var cartModel: ShoppingCartViewModel

    public var body: some View {
        VStack {
            if cartModel.items.isEmpty {
                Spacer()
            } else {
                List {
                    ForEach(cartModel.items) { item in
                        CartRowView(item: item)
                            .environmentObject(cartModel)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 4))
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
//                .scrollContentBackground(.hidden)
            }
        }
        .alert(isPresented: $cartModel.productError) {
            Alert(
                title: Text(keyed: "Snabble.SaleStop.ErrorMsg.title"),
                message: Text(cartModel.productErrorMessage),
                dismissButton:
                        .default(Text(keyed: "Snabble.ok"),
                                 action: {
                                     cartModel.productError = false
                                 }))
                
        }
        .alert(isPresented: $cartModel.voucherError) {
            Alert(
                title: Text(keyed: "Snabble.InvalidDepositVoucher.errorMsg"),
                message: nil,
                dismissButton:
                        .default(Text(keyed: "Snabble.ok"),
                                 action: {
                                     cartModel.voucherError = false
                                 }))
        }
    }
}

public struct ShoppingCartView: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    
    init(shoppingCart: ShoppingCart) {
        self.cartModel = ShoppingCartViewModel(shoppingCart: shoppingCart)
    }
    
    public var body: some View {
        ShoppingCartItemsView(cartModel: cartModel)
    }
    
}
