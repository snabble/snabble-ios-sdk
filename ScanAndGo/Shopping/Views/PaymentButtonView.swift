//
//  PaymentButtonView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 08.09.23.
//

import SwiftUI

import SnabbleCore
import SnabbleUI
import SnabbleAssetProviding

struct PaymentButtonView: View {
    @Environment(Shopper.self) var model
    let onAction: () -> Void
    
    var body: some View {
        Button(action: {
            onAction()
        }, label: {
            HStack {
                if let icon = model.paymentIcon {
                    Spacer(minLength: 2)
                    SwiftUI.Image(uiImage: icon)
                        .animation(.smooth, value: icon)
                        .padding(.vertical, 8)
                } else {
                    Text(Asset.localizedString(forKey: "Snabble.Shoppingcart.BuyProducts.selectPaymentMethod"))
                        .padding(.vertical, 8)
                    Spacer()
                }
                Spacer(minLength: 2)
                Image(systemName: "chevron.down")
            }
            .contentShape(Rectangle())
        })
        .buttonStyle(BorderedButtonStyle())
    }
}
