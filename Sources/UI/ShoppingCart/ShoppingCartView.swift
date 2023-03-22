//
//  ShoppingCartView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

// struct CouponItemView: View {
//    let coupon: CartCoupon
//    @ObservedObject var itemModel: CartItemModel
//
//    init(coupon: CartCoupon, for lineItem: CheckoutInfo.LineItem) {
//        self.itemModel = CartItemModel(item: item, for: lineItems)
//    }
//
//    init(coupon: CartCoupon) {
//        self.coupon = coupon
//    }
//    var body: some View {
//
//    }
//    func setCouponItem(_ coupon: CartCoupon, for lineItem: CheckoutInfo.LineItem?) {
//        self.quantity = 1
//        self.cellView?.nameView?.nameLabel?.text = coupon.coupon.name
//        self.rightDisplay = .trash
//
//        self.quantityText = "1"
//
//        let redeemed = lineItem?.redeemed == true
//
//        if showImages {
//            let icon: UIImage? = Asset.image(named: "SnabbleSDK/icon-percent")
//            self.cellView?.imageView?.imageView?.image = icon?.recolored(with: redeemed ? .label : .systemGray)
//            self.leftDisplay = .image
//        } else {
//            self.leftDisplay = .badge
//            self.badgeText = "%"
//            self.badgeColor = redeemed ? .systemRed : .systemGray
//        }
//    }
// }

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

public struct ShoppingCartItemsView<Footer: View>: View {
    @ObservedObject var cartModel: ShoppingCartViewModel

    var footer: Footer
    
    public var body: some View {
        VStack {
            if cartModel.items.isEmpty {
                Spacer()
            } else {
                List {
                    Section(footer: footer) {
                        ForEach(cartModel.cartItems, id: \.id) { item in
                            CartItemView(itemModel: item)
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
    private func delete(at offset: IndexSet) {
        cartModel.trash(at: offset)
    }
}

public struct ShoppingCartView: View {
    @ObservedObject var cartModel: ShoppingCartViewModel
    @State var total: Int = 0
    @State var regularTotal: Int = 0
    @State var badgeView: Bool = UserDefaults.displayBadgedDiscount
    let compactMode: Bool
    
    init(shoppingCart: ShoppingCart, compactMode: Bool = false) {
        self.cartModel = ShoppingCartViewModel(shoppingCart: shoppingCart)
        self.compactMode = compactMode
    }
    
    @ViewBuilder
    var footer: some View {
        if !compactMode {
            HStack(spacing: 0) {
                SwiftUI.Image(systemName: "cart")
                    .cartImageModifier(padding: 10)
                    .padding(.leading, -8)
                    .padding(.trailing, 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    if total != regularTotal {
                        HStack {
                            Text(cartModel.formatter.format(regularTotal))
                                .strikethrough()
                            Text(cartModel.formatter.format(regularTotal - total) + " " + Asset.localizedString(forKey: "Snabble.Shoppingcart.saved"))
                            
                        }
                        .foregroundColor(.secondary)
                    }
                    Text(cartModel.formatter.format(total))
                        .font(.headline)
                }
                Spacer()
                Text(cartModel.numberOfProductsString)
            }
            .onTapGesture(count: 3) {
                badgeView.toggle()
            }
            .listRowBackground(Color.tertiarySystemGroupedBackground)
        }
    }
    
    public var body: some View {
        if cartModel.cartItems.isEmpty {
            if !compactMode {
                Text(keyed: "Snabble.Shoppingcart.EmptyState.description")
            }
        } else {
            ShoppingCartItemsView(cartModel: cartModel, footer: footer)
                .drawDiscountBadge(badgeView)
                .onAppear {
                    updateView()
                }
                .onChange(of: cartModel.updated) { _ in
                    updateView()
                }
        }
    }
    private func updateView() {
        total = cartModel.total
        regularTotal = cartModel.regularTotal
    }
}
