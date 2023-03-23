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
