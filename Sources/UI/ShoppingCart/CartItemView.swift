//
//  CartItemView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

struct DiscountBadgeView: View {
    let discount: String
    
    let showBadge: Bool
    let showBadgeLabel: Bool
    let showPercentValue: Bool
    
    init(discount: String, showBadge: Bool = true, showBadgeLabel: Bool = true, showPercentValue: Bool = true) {
        self.discount = discount
        self.showBadge = showBadge
        self.showBadgeLabel = showBadgeLabel
        self.showPercentValue = showPercentValue
    }
    
    var body: some View {
        ZStack {
            if let image = Asset.image(named: "SnabbleSDK/icon-discount") {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.red)
            }
            Image(systemName: "percent")
                .font(Font.title.weight(.heavy))
                .foregroundColor(.white)
                .opacity(0.33)
            Text(discount)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.66), radius: 2)
        }
    }
}

struct CartItemView: View {
    @ObservedObject var itemModel: CartItemModel
    
    init(item: CartItem, for lineItems: [CheckoutInfo.LineItem]) {
        self.itemModel = CartItemModel(item: item, for: lineItems)
    }
    @ViewBuilder
    var price: some View {
        if itemModel.hasDiscount {
            HStack {
                Text(itemModel.discountedPriceString)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(itemModel.regularPriceString)
                    .strikethrough(true)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
        } else {
            Text(itemModel.regularPriceString)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    @ViewBuilder
    var filler: some View {
        Spacer(minLength: 0)
        if itemModel.hasDiscount {
            DiscountBadgeView(discount: itemModel.discountPercentString)
        }
    }
        
    @ViewBuilder
    var leftView: some View {
        if let image = itemModel.image {
            image
                .cartImageModifier()
        } else if itemModel.leftDisplay == .emptyImage {
            SwiftUI.Image(systemName: "basket")
                .cartImageModifier(padding: 10)
        }
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
    @ViewBuilder
    var additionalInfo: some View {
        if let discountName = itemModel.discountName {
            HStack {
                Text(itemModel.discountString)
                Spacer()
                Text(discountName)
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.leading, 54)
            .padding(.trailing, 8)
            .padding(.bottom, 4)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                leftView
                VStack(alignment: .leading) {
                    Text(itemModel.title)
                    price
                }
                filler
                rightView
                    .padding(.trailing, 8)
            }
            additionalInfo
        }
    }
}

struct DiscountView: View {
    let amount: String
    
    init(amount: Int) {
        self.amount = PriceFormatter(SnabbleCI.project).format(amount)
    }
    @ViewBuilder
    var leftView: some View {
        SwiftUI.Image(systemName: "percent")
            .cartImageModifier(padding: 10)
    }
    
    var body: some View {
        HStack {
            leftView
            VStack(alignment: .leading) {
                Text(Asset.localizedString(forKey: "Snabble.Shoppingcart.discounts"))
                Text(amount)
                    .font(.footnote)
                    .foregroundColor(.secondary)

            }
        }
    }
}
