//
//  CouponItemView.swift
//  
//
//  Created by Uwe Tilemann on 12.04.23.
//

import Foundation
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

struct CouponItemView: View {
    @ObservedObject var itemModel: CouponCartItemModel
    let showImages: Bool
    
    init(itemModel: CouponCartItemModel, showImages: Bool = true) {
        self.itemModel = itemModel
        self.showImages = showImages
    }

    @ViewBuilder
    var leftView: some View {
        if showImages {
            SwiftUI.Image(systemName: "percent")
                .cartImageModifier(padding: 10)
                .foregroundColor(itemModel.isRedeemed ? .primary : .secondary)
        }
    }

    var body: some View {
        HStack {
            leftView
            VStack(alignment: .center, spacing: 4) {
                HStack(alignment: .top) {
                    Spacer()
                    Text(itemModel.cartCoupon.coupon.name)
                    Asset.image(named: "discount-badge")
                }

                if itemModel.isRedeemed == false {
                    Text(keyed: "Snabble.Coupon.notUsable")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                }
            }
            .cartInfo()
        }
        .listRowBackground(Color.clear)
    }
}
