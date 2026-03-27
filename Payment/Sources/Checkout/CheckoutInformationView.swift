//
//  CheckoutInformationView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.02.23.
//
import SwiftUI
import Combine

protocol CheckoutInformationViewModel {
    var text: String { get }
    var actionTitle: String? { get }
    var userInfo: [String: Any]? { get }
}

struct CheckoutInformationView: View {
    let model: CheckoutInformationViewModel
    let checkoutModel: CheckoutModel

    init(model: CheckoutInformationViewModel, checkoutModel: CheckoutModel) {
        self.model = model
        self.checkoutModel = checkoutModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.text)
                .onTapGesture {
                    if model.actionTitle == nil {
                        checkoutModel.actionPublisher.send(model.userInfo)
                    }
                }
            if let title = model.actionTitle {
                Button(action: {
                    checkoutModel.actionPublisher.send(["action": title])
                }) {
                    Text(title)
                        .foregroundColor(.systemRed)
                }
            }
        }
        .font(.footnote)
    }
}

extension CheckoutStep: CheckoutInformationViewModel {}
