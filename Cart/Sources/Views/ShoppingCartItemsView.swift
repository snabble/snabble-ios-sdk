//
//  ShoppingCartItemsView.swift
//  
//
//  Created by Uwe Tilemann on 22.03.23.
//

import SwiftUI
import SnabbleAssetProviding

extension ShoppingCartViewModel {
    @ViewBuilder
    func view(for item: CartEntry) -> some View {
        if case .cartItem(let item, let lineItems) = item {
            let discounts: [ShoppingCartItemDiscount] = discountItems(item: item, for: lineItems)
            let itemModel = ProductItemModel(item: item, for: lineItems, discounts: discounts, showImages: showImages)
            CartItemView(itemModel: itemModel) { @MainActor discount in
                self.trash(discount: discount)
            }
        } else if case .discount(let int) = item {
            DiscountItemView(amount: int, description: totalDiscountDescription, showImages: showImages) { @MainActor in
                self.trash(item: item)
            }
            .padding(.trailing, 8)
            .deleteDisabled(true)
        } else if case .coupon(let cartCoupon, let lineItem) = item {
            // As long as the BE deliviers no couponId we add an Item here
//            if lineItem == nil || lineItem?.redeemed == false {
                let itemModel = CouponCartItemModel(cartCoupon: cartCoupon, for: lineItem, showImages: showImages)
                CouponItemView(itemModel: itemModel, showImages: false) { @MainActor in
                    self.trash(item: item)
                }
                .padding(.trailing, 8)
//            }
        } else if case .voucher(let cartVoucher, let lineItems) = item {
            VoucherItemView(voucher: cartVoucher.voucher, lineItems: lineItems) { @MainActor in
                self.trash(item: item)
            }
            .padding(.trailing, 8)
        }
    }
}

public struct ShoppingCartItemsView<Footer: View>: View {
    @Bindable var cartModel: ShoppingCartViewModel
    var footer: Footer

    @State private var itemToDelete: CartEntry? = nil
    @State private var showingDeleteAlert = false

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
                            .environment(cartModel)
                            .swipeActions(allowsFullSwipe: false) {
                                 Button {
                                     cartModel.trash(item: item)
                                 } label: {
                                     Label(Asset.localizedString(forKey: "Snabble.ShoppingList.EditList.delete"), systemImage: "trash")
                                 }
                             }
                             .tint(.red)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 4))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollBounceBehavior(.basedOnSize)
            .scrollContentBackground(.hidden)
            .background(.clear)
        }
    }

    public var body: some View {
        content
            .alert(
                Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.title"),
                isPresented: $cartModel.productError
            ) {
                Button("Snabble.ok") {
                    cartModel.productError = false
                }
            } message: {
                Text(cartModel.productErrorMessage)
            }
            .alert(
                Asset.localizedString(forKey: "Snabble.ShoppingList.EditList.delete"),
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
