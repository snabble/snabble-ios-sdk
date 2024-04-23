//
//  DiscountItemView.swift
//  
//
//  Created by Uwe Tilemann on 21.03.23.
//

import SwiftUI
import SnabbleCore

struct DiscountItemView: View {
    let amount: String
    var description: String?
    let showImages: Bool
    
    init(amount: Int, description: String? = nil, showImages: Bool = true) {
        self.amount = PriceFormatter(SnabbleCI.project).format(amount)
        self.description = description
        self.showImages = showImages
    }

    @ViewBuilder
    var leftView: some View {
        if showImages {
            SwiftUI.Image(systemName: "percent")
                .cartImageModifier(padding: 10)
        }
    }
    
    var body: some View {
        HStack {
            leftView
            VStack(alignment: .leading, spacing: 12) {
                Text(Asset.localizedString(forKey: "Snabble.Shoppingcart.discounts"))
                HStack(alignment: .top) {
                    Text(amount)
                        .cartPrice()
                    Spacer()
                    Text(description ?? "")
                    Image(systemName: "discount-badge")
                }
                .cartInfo()
           }
        }
        .listRowBackground(Color.clear)
    }
}
