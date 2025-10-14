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
        } else if case .coupon(_, let lineItem) = item {
            if let lineItem = lineItem, lineItem.redeemed == false {
                // CouponCartItems are currenly not redeemed
                // see: https://snabble.atlassian.net/browse/APPS-1688
//                let itemModel = CouponCartItemModel(cartCoupon: cartCoupon, for: lineItem)
//                CouponItemView(itemModel: itemModel, showImages: showImages)
            }
        } else if case .voucher(let cartVoucher, let lineItems) = item {
            VoucherItemView(voucher: cartVoucher.voucher, lineItems: lineItems) {
                self.trash(item: item)
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
        if cartModel.items.isEmpty {
            VStack {
                Spacer()
            }
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
            .listStyle(.plain)
            .scrollBounceBehavior(.basedOnSize)
            .background(.clear)
            .hiddenScrollView()
        }
    }

    public var body: some View {
        content
            .alert(
                "Snabble.SaleStop.ErrorMsg.title",
                isPresented: $cartModel.productError
            ) {
                Button("Snabble.ok") {
                    cartModel.productError = false
                }
            } message: {
                Text(cartModel.productErrorMessage)
            }
            .alert(
                "",
                isPresented: $cartModel.confirmDeletion
            ) {
                Button(role: .destructive) {
                    cartModel.processDeletion()
                } label: {
                    Text(keyed: "Snabble.yes")
                }
                Button(role: .cancel) {
                    cartModel.cancelDeletion()
                } label: {
                    Text(keyed: "Snabble.no")
                }
            } message: {
                Text(cartModel.deletionMessage)
            }
    }

    private func delete(at offset: IndexSet) {
        cartModel.trash(at: offset)
    }
}
