//
//  CheckoutView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 18.06.24.
//

import SwiftUI
import Combine

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
import SnabbleUI

struct CheckoutView: View {
    @AppStorage("io.snabble.sdk.scanAndGo.paymentMethod") private var paymentMethod: String?
    
    @ObservedObject var model: Shopper
    
    @State private var disableCheckout: Bool = true
    
    @State private var countString: String = ""
    @State private var totalString: String = ""
    @State private var showPaymentSelector: Bool = false
    
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
                        .foregroundStyle(model.totalPrice ?? 0 >= 0 ? Color.primary : Color.systemRed)
                }
                HStack(spacing: 16) {
                    if model.hasValidPayment {
                        PaymentButtonView(model: model, onAction: {
                            showPaymentSelector = true
                        })
                        .frame(width: 88, height: 38)
                        
                        if model.paymentManager.selectedPayment != nil {
                            PrimaryButtonView(title: Asset.localizedString(forKey: model.totalPrice ?? 0 > 0 ? "Snabble.Shoppingcart.BuyProducts.now" : "Snabble.Shoppingcart.completePurchase"),
                                              disabled: $disableCheckout, onAction: {
                                model.startCheckout()
                            })
                        }
                    } else {
                        PaymentButtonView(model: model, onAction: {
                            showPaymentSelector = true
                        })
                        .frame(minWidth: 88, maxWidth: .infinity)
                    }
                }
                .bottomSheet(isPresented: $showPaymentSelector) {
                    PaymentSelectionView(project: model.project,
                                         availablePayments: model.projectPayments,
                                         supportedPayments: model.supportedShoppingCartPayments) { paymentItem in
                        if let paymentItem {
                            model.paymentManager.setSelectedPaymentItem(paymentItem)
                            if let name = paymentItem.methodDetail?.displayName {
                                paymentMethod = name
                            }
                        }
                        showPaymentSelector = false
                    }
                }
           }
            .padding([.leading, .trailing], 16)
            .padding(.bottom, 10)
            Divider()
        }
        .onAppear {
            model.paymentManager.update()
        }
        .task {
            update()
            let items = model.project.paymentItems(for: model.supportedShoppingCartPayments)
                .filter({ model.projectPayments.contains($0.method) && $0.active == true && $0.methodDetail != nil })
            if let name = paymentMethod, !items.isEmpty {
                if let index = items.firstIndex(where: { $0.methodDetail?.displayName == name }) {
                    model.paymentManager.setSelectedPaymentItem(items[index])
                }
            }
            if model.paymentManager.selectedPayment == nil, let firstPayment = items.first {
                model.paymentManager.setSelectedPaymentItem(firstPayment)
            }
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
