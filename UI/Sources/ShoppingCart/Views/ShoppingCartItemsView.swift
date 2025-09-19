//
//  ShoppingCartItemsView.swift
//  
//
//  Created by Uwe Tilemann on 22.03.23.
//

import SwiftUI
import SnabbleCore
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
        if case .cartItem(_, _) = item {
            CartItemView(cartEntry: item)
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

extension ShoppingCartViewModel {
    public var confirmDeletionAlert: Alert {
        Alert(
            title: Text(""),
            message: Text(deletionMessage),
            primaryButton:
                    .destructive(Text(keyed: "Snabble.yes"),
                                 action: {
                                     self.processDeletion()
                                 }),
            secondaryButton:
                    .cancel(Text(keyed: "Snabble.no"),
                            action: {
                                self.cancelDeletion()
                            }))
        
    }

    public var productErrorAlert: Alert {
        Alert(
            title: Text(keyed: "Snabble.SaleStop.ErrorMsg.title"),
            message: Text(self.productErrorMessage),
            dismissButton:
                    .default(Text(keyed: "Snabble.ok"),
                             action: {
                                 self.productError = false
                             }))
    }
}

public struct ShoppingCartItemsView<Footer: View>: View {
    @Environment(ShoppingCartViewModel.self) var cartModel
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
                            .environment(cartModel)
                    }
                    .onDelete(perform: delete)
                    .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 4))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .background(.clear)
            .hiddenScrollView()
        }
    }

    public var body: some View {
        content
            .alert(isPresented: .constant(cartModel.productError)) {
                cartModel.productErrorAlert
            }
            .alert(isPresented: .constant(cartModel.confirmDeletion)) {
                cartModel.confirmDeletionAlert
            }
    }

    private func delete(at offset: IndexSet) {
        cartModel.trash(at: offset)
    }

}
