//
//  ShoppingCartItemsView.swift
//  
//
//  Created by Uwe Tilemann on 22.03.23.
//

import SwiftUI
import SnabbleAssetProviding

struct HiddenScrollView: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

extension View {
    func hiddenScrollView() -> some View {
        return modifier(HiddenScrollView())
    }
}

extension ShoppingCartViewModel {
    @ViewBuilder
    func view(for item: CartEntry) -> some View {
        if case .cartItem(let item, let lineItems) = item {
            let discounts: [ShoppingCartItemDiscount] = discountItems(item: item, for: lineItems)
            let itemModel = ProductItemModel(item: item, for: lineItems, discounts: discounts, showImages: showImages)
            CartItemView(itemModel: itemModel)
        } else if case .discount(let int) = item {
            DiscountItemView(amount: int, description: totalDiscountDescription, showImages: showImages)
                .deleteDisabled(true)
        } else if case .coupon(let cartCoupon, let lineItem) = item {
            if let lineItem = lineItem, lineItem.redeemed == false {
                let itemModel = CouponCartItemModel(cartCoupon: cartCoupon, for: lineItem)
                CouponItemView(itemModel: itemModel, showImages: showImages)
            }
        }
    }
}

private struct ItemsAsListView<Footer: View>: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    var footer: Footer

    var body: some View {
        VStack {
            if cartModel.items.isEmpty {
                Spacer()
            } else {
                List {
                    Section(footer: footer) {
                        ForEach(cartModel.items, id: \.id) { item in
                            cartModel.view(for: item)
                                .environmentObject(cartModel)
                        }
                        .onDelete(perform: delete)
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 4))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
                .hiddenScrollView()
            }
        }
    }
    private func delete(at offset: IndexSet) {
        cartModel.trash(at: offset)
    }
}

private struct ItemsAsCustomView<Footer: View>: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    var footer: Footer

    var body: some View {
        VStack {
            if cartModel.items.isEmpty {
                Spacer()
            } else {
                ForEach(cartModel.items, id: \.id) { item in
                    VStack {
                        cartModel.view(for: item)
                            .environmentObject(cartModel)
                            .padding([.top, .bottom, .trailing], 4)
                        Divider()
                            .padding(.leading, 52)
                    }
                    .padding(.leading, 10)
                }
                footer
            }
        }
    }
}

public struct ShoppingCartItemsView<Footer: View>: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    var footer: Footer
    var asList: Bool = true
    
    @ViewBuilder
    var content: some View {
        if asList {
            ItemsAsListView(cartModel: cartModel, footer: footer)
        } else {
            ItemsAsCustomView(cartModel: cartModel, footer: footer)
        }
    }

    public var body: some View {
        content
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
        .alert(isPresented: $cartModel.confirmDeletion) {
            Alert(
                title: Text(""),
                message: Text(cartModel.deletionMessage),
                primaryButton:
                        .destructive(Text(keyed: "Snabble.yes"),
                                     action: {
                                         cartModel.processDeletion()
                                     }),
                secondaryButton:
                        .cancel(Text(keyed: "Snabble.no"),
                                action: {
                                    cartModel.cancelDeletion()
                                }))
        }
    }
}
