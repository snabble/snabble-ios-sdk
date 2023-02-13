//
//  CheckoutStepView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 06.02.23.
//
import SwiftUI

protocol CheckoutStepViewModel {
    var statusViewModel: CheckoutStepStatusViewModel { get }
    var text: String { get }
    var detailText: String? { get }
    var actionTitle: String? { get }
    var image: UIImage? { get }
}

struct CheckoutStepView: View {
    var model: CheckoutStepViewModel
    @EnvironmentObject var checkoutModel: CheckoutModel

    init(model: CheckoutStepViewModel) {
        self.model = model
    }
    
    var body: some View {
        HStack {
            CheckoutStepStatusView(model: model.statusViewModel)
            VStack {
                Text(model.text)
                if let detail = model.detailText {
                    Text(detail)
                }
                if let image = model.image {
                    SwiftUI.Image(uiImage: image)
                }
                if let action = model.actionTitle {
                    Button(action: {
                        checkoutModel.actionPublisher.send(["action" : model.text])
                    }) {
                        Text(action)
                    }
                }
            }
        }
    }
}

extension CheckoutStep: CheckoutStepViewModel {
    var statusViewModel: CheckoutStepStatusViewModel {
        status ?? .loading
    }
}
