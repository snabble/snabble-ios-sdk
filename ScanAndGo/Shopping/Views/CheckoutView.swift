//
//  CheckoutView.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 18.06.24.
//

import SwiftUI
import Combine

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

struct CheckoutView: View {
    @ObservedObject var model: Shopper
    
    @State private var disableCheckout: Bool = true
    
    @State private var countString: String = ""
    @State private var totalString: String = ""
    
    @State var cancellables = Set<AnyCancellable>()
    
    init(model: Shopper) {
        self.model = model
        
        NotificationCenter.default.publisher(for: .snabbleCartUpdated)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
            })
            .store(in: &cancellables)
    }
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text(countString)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(totalString)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                HStack(spacing: 16) {
                    PaymentButtonView(model: model, onAction: {
                        model.sendAction(.alertSheet(model.paymentManager))
                    })
                    PrimaryButtonView(title: Asset.localizedString(forKey: "Snabble.Shoppingcart.BuyProducts.now"),
                                      disabled: $disableCheckout, onAction: {
                        model.startCheckout()
                    })
                }
            }
            .padding([.leading, .trailing], 16)
            .padding(.bottom, 10)
            Divider()
        }
        .task {
            update()
        }
        .onReceive(NotificationCenter.default.publisher(for: .snabbleCartUpdated)) { _ in
            update()
        }
    }
    
    private func update() {
        countString = model.numberOfItemsInCart
        totalString = model.totalPriceString
        disableCheckout = !model.canCheckout
    }
}
