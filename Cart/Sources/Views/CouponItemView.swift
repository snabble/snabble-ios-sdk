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
    var itemModel: CouponCartItemModel
    let showImages: Bool
    var onDelete: (() -> Void)?

    init(itemModel: CouponCartItemModel, showImages: Bool = true, onDelete: (() -> Void)? = nil) {
        self.itemModel = itemModel
        self.showImages = showImages
        self.onDelete = onDelete
    }

    @ViewBuilder
    var leftView: some View {
        if showImages {
            Image(systemName: "percent")
                .cartImageModifier(padding: 10)
                .foregroundColor(itemModel.isRedeemed ? .primary : .secondary)
        }
    }

    @ViewBuilder
    var couponView: some View {
        HStack {
            VStack(alignment: .center, spacing: 4) {
                Text(itemModel.cartCoupon.coupon.name)

                if itemModel.isRedeemed == false {
                    Text(keyed: "Snabble.Coupon.notUsable")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(.secondaryLabel)
                }
            }
            Spacer()
            Button {
                onDelete?()
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(Color.onProjectPrimary())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.projectPrimary().opacity(0.25))
        }
    }
    
    var body: some View {
        if showImages {
            HStack {
                leftView
                couponView
            }
        } else {
            couponView
        }
    }
}
