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
    @ObservedObject var itemModel: ProductItemModel
    
    init(itemModel: ProductItemModel) {
        self.itemModel = itemModel
    }
    
    @ViewBuilder
    var price: some View {
        if itemModel.hasDiscount {
            HStack {
                Text(itemModel.reducedPriceString)
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
            
        case .weightEntry:
            CartWeightView(itemModel: itemModel, editable: true)
            
        case .weightDisplay:
            CartWeightView(itemModel: itemModel)

        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    var additionalInfo: some View {
        if let depositInfo = itemModel.depositDetailString {
            Text(depositInfo)
                .cartInfo()
        }
        if let modifiedPriceString = itemModel.modifiedPriceString {
            HStack {
                Text(modifiedPriceString)
                Spacer()
                Text(itemModel.modifiedPriceText)
            }
            .cartInfo()
        }
        ForEach(itemModel.discounts) { discount in
            if let discountPriceString = itemModel.formatter.format(discount.discount) {
                HStack {
                    Text(discountPriceString)
                    Spacer()
                    Text(discount.name)
                }
                .cartInfo()
            }
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
