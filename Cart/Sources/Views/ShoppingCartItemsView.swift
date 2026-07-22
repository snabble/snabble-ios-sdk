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

// Preference key to propagate the first two row heights out of the List without
// triggering the "Geometry action is cycling" warning that onGeometryChange causes
// when used inside List in iOS 18.
private struct RowHeightPreferenceKey: PreferenceKey {
    typealias Value = [Int: CGFloat]
    static let defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { max($0, $1) })
    }
}

public struct ShoppingCartItemsView<Footer: View>: View {
    @Bindable var cartModel: ShoppingCartViewModel
    var footer: Footer
    var onPreviewRowHeight: ((Int, CGFloat) -> Void)?

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
                    ForEach(Array(cartModel.items.enumerated()), id: \.element.id) { index, item in
                        cartModel.view(for: item)
                            .environment(cartModel)
                            .background {
                                // Only measure the first two rows — using GeometryReader +
                                // PreferenceKey avoids the cycling warning that onGeometryChange
                                // produces inside List (known iOS 18 issue).
                                if index < 2 {
                                    GeometryReader { geo in
                                        Color.clear.preference(
                                            key: RowHeightPreferenceKey.self,
                                            value: [index: geo.size.height]
                                        )
                                    }
                                }
                            }
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
            .onPreferenceChange(RowHeightPreferenceKey.self) { heights in
                for (index, height) in heights where height > 0 {
                    onPreviewRowHeight?(index, height)
                }
            }
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
