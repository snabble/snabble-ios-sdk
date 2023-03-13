//
//  CartItemView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

open class CartItemModel: ObservableObject {
    let item: CartItem
    let lineItems: [CheckoutInfo.LineItem]

    @Published var quantity: Int
    @Published var title: String
    @Published var price: Int

    @Published var leftDisplay: LeftDisplay = .none
    @Published var rightDisplay: RightDisplay = .buttons

    init(item: CartItem, for lineItems: [CheckoutInfo.LineItem]) {
        self.item = item
        self.lineItems = lineItems
        
        let defaultItem = lineItems.first { $0.type == .default }

        self.quantity = defaultItem?.weight ?? defaultItem?.amount ?? item.quantity

        let product = item.product
        self.title = defaultItem?.name ?? product.name

        if item.editable {
            if product.type == .userMustWeigh {
                self.rightDisplay = .weightEntry
            } else {
                self.rightDisplay = .buttons
            }
        } else if product.type == .preWeighed {
            self.rightDisplay = .weightDisplay
        }

//        self.showQuantity()

        // suppress display when price == 0
        self.price = defaultItem?.totalPrice ?? item.price
        
        self.loadImage()
    }
    
    var subtitle: String? {
        guard self.price != 0 else {
            return nil
        }
        let formatter = PriceFormatter(SnabbleCI.project)
        if let defaultItem = lineItems.first(where: { $0.type == .default }) {
            if let depositTotal = lineItems.first(where: { $0.type == .deposit })?.totalPrice {
                let total = formatter.format((defaultItem.totalPrice ?? 0) + depositTotal)
                let includesDeposit = Asset.localizedString(forKey: "Snabble.Shoppingcart.includesDeposit")
                return "\(total) \(includesDeposit)"
            } else {
                return formatter.format(defaultItem.totalPrice ?? 0)
            }
        } else {
            return formatter.format(item.price)
        }
    }

    func loadImage() {
    }
}

struct CartItemView: View {
    @ObservedObject var itemModel: CartItemModel
    
    init(item: CartItem, for lineItems: [CheckoutInfo.LineItem]) {
        self.itemModel = CartItemModel(item: item, for: lineItems)
    }
    
    @ViewBuilder
    var rightView: some View {
        switch itemModel.rightDisplay {
        case .buttons:
            CartStepperView(itemModel: itemModel)
            
        default:
            EmptyView()
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(itemModel.title)
                Text(itemModel.subtitle ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            rightView
                .padding(.trailing, 8)
        }
    }
}
