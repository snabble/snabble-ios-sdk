//
//  CartItemView.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

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

extension ShoppingCartItemDiscount {

    @ViewBuilder
    public var image: SwiftUI.Image? {
        Asset.image(named: "discount-badge")
    }
}

struct BadgeTextView: View {
    let badgeText: String
    let badgeColor: SwiftUI.Color
    
    init(badgeText: String?, badgeColor: ColorStyle? = nil) {
        self.badgeText = badgeText ?? "%"
        self.badgeColor = badgeColor?.color ?? .systemRed
    }
    
    var body: some View {
        Text(badgeText)
            .font(.footnote)
            .padding([.top, .bottom], 1)
            .padding([.leading, .trailing], 2)
            .background(RoundedRectangle(cornerRadius: 4).foregroundColor(badgeColor))
            .foregroundColor(.white)
    }
}

struct CartItemView: View {
    @ObservedObject var itemModel: ProductItemModel
    @ScaledMetric var scale: CGFloat = 1
    
    init(itemModel: ProductItemModel) {
        self.itemModel = itemModel
    }
    
    @ViewBuilder
    var price: some View {
        if itemModel.hasDiscount {
            HStack {
                Text(itemModel.regularPriceString ?? "")
                    .cartPrice()
                Text(itemModel.reducedPriceString)
                    .strikethroughPrice()
            }
            
        } else {
            Text(itemModel.regularPriceString ?? "")
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
                BadgeTextView(badgeText: badgeText)
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

        ForEach(itemModel.discounts) { discount in
            HStack(alignment: .top) {
                if discount.discount != 0 {
                    Text(itemModel.formatter.format(discount.discount * (discount.discount > 0 ? -1 : 1)))
                }
                Spacer()
                Text(discount.name)
                
                if let image = discount.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16 * scale, height: 16 * scale)
                }
            }
            .cartInfo()
        }
    }
    
    var body: some View {
        HStack {
            leftView
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(itemModel.title)
                        price
                    }
                    Spacer(minLength: 4)
                    rightView
                        .padding(.trailing, 8)
                }
                .padding([.top, .bottom], 6)
                additionalInfo
            }
        }
        .listRowBackground(Color.clear)
    }
}
