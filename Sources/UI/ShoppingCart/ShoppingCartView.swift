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

//    @ViewBuilder
//    var image: some View {
//        if let image = item.image {
//            image
//                .resizable()
//                .scaledToFit()
//                .clipShape(RoundedRectangle(cornerRadius: 4))
//                .frame(width: 48, height: 48)
//                .padding(0)
//                .padding(.trailing, 8)
//        }
//    }
//
//    @ViewBuilder
//    var price: some View {
//        if item.hasDiscount {
//            HStack {
//                Text(model.formatter.string(for: item.regularPrice) ?? "")
//                    .strikethrough(true)
//                    .font(.footnote)
//                    .foregroundColor(.secondary)
//                Text(model.formatter.string(for: item.discountedPrice) ?? "")
//                    .font(.footnote)
//                    .foregroundColor(.secondary)
//           }
//
//        } else {
//            Text(model.formatter.string(for: item.regularPrice) ?? "")
//                .font(.footnote)
//                .foregroundColor(.secondary)
//        }
//    }
//    @ViewBuilder
//    var discount: some View {
//        if item.hasDiscount {
//            HStack(spacing: 0) {
//                Spacer()
//                ZStack {
//                    Image(systemName: "seal.fill")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 40, height: 40)
//                        .foregroundColor(.red)
//
//                    Image(systemName: "percent")
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                        .opacity(0.66)
//                    Text("\(item.discount)")
//                        .font(.headline)
//                        .fontWeight(.heavy)
//                        .foregroundColor(.white)
//                        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.66), radius: 2)
//                }
//            }
//        }
//    }
    
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
//        case .discount(let amount):
//            DiscountView(for: amount)
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

public struct ShoppingCartView: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    
    init(shoppingCart: ShoppingCart) {
        self.cartModel = ShoppingCartViewModel(shoppingCart: shoppingCart)
    }
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
