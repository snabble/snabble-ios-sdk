//
//  CouponItemView.swift
//  
//
//  Created by Uwe Tilemann on 22.03.23.
//

import SwiftUI
import SnabbleCore

struct CouponItemView: View {
    @ObservedObject var itemModel: CouponCartItemModel
    
    @ViewBuilder
    var leftView: some View {
        if itemModel.showImages {
            SwiftUI.Image(systemName: "percent")
                .cartImageModifier(padding: 10)
                .foregroundColor(itemModel.badgeColor.color)
        } else {
            BadgeTextView(badgeText: itemModel.badgeText, badgeColor: itemModel.badgeColor)
        }
    }

    var body: some View {
        HStack {
            leftView
            VStack(alignment: .leading, spacing: 12) {
                Text(itemModel.title)
                Text(itemModel.subtitle)
                    .cartInfo()
            }
        }
    }
}
