//
//  CartItemView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore

extension Text {
    func cartPrice() -> some View {
        self
            .font(.footnote)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }

    func strikethroughPrice() -> some View {
        self
            .font(.footnote)
            .strikethrough(true)
            .foregroundColor(.secondary)
    }
}

struct CartItemView: View {
    @ObservedObject var itemModel: CartItemModel
    
    init(itemModel: CartItemModel) {
        self.itemModel = itemModel
    }
    
    @ViewBuilder
    var price: some View {
        if itemModel.hasDiscount {
            HStack {
                Text(itemModel.discountedPriceString)
                    .cartPrice()
                Text(itemModel.regularPriceString)
                    .strikethroughPrice()
            }
            
        } else {
            Text(itemModel.regularPriceString)
                .cartPrice()
        }
    }
    
    @ViewBuilder
    var leftView: some View {
        ZStack(alignment: .topLeading) {
            if itemModel.showImages {
                if let image = itemModel.image {
                    image
                        .cartImageModifier()
                } else if itemModel.leftDisplay == .emptyImage {
                    SwiftUI.Image(systemName: "basket")
                        .cartImageModifier(padding: 10)
                }
            }
            if let badgeText = itemModel.badgeText {
                Text(badgeText)
                    .font(.footnote)
                    .padding([.top, .bottom], 1)
                    .padding([.leading, .trailing], 2)
                    .background(RoundedRectangle(cornerRadius: 4).foregroundColor(.red))
                    .foregroundColor(.white)
            }
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
            .cartInfo()
        } else if let depositInfo = itemModel.depositDetailString {
            Text(depositInfo)
                .cartInfo()
        }
    }
    
    var body: some View {
        HStack {
            leftView
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(itemModel.title)
                        price
                    }
                    Spacer(minLength: 0)
                    rightView
                        .padding(.trailing, 8)
                }
                additionalInfo
            }
        }
        .listRowBackground(itemModel.hasDiscount ? Color.tertiarySystemGroupedBackground : Color.clear)
    }
}
