//
//  CheckoutStep.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//

import Foundation

struct CheckoutStep {
    enum Kind {
        case `default`
        case information
    }

    let status: CheckoutStepStatus?
    let text: String
    let detailText: String?
    let actionTitle: String?
    let image: UIImage?

    var kind: Kind {
        if status == nil, detailText == nil, image == nil {
            return .information
        } else {
            return .default
        }
    }
}

extension CheckoutStep: Hashable {
    static func == (lhs: CheckoutStep, rhs: CheckoutStep) -> Bool {
        lhs.status == rhs.status &&
        lhs.text == rhs.text &&
        lhs.detailText == rhs.detailText &&
        lhs.actionTitle == rhs.actionTitle &&
        lhs.image == rhs.image
    }
}

extension CheckoutStep {
    init(paymentStatus: PaymentStatus) {
        switch paymentStatus {
        case .loading:
            status = .loading
            detailText = nil
            actionTitle = nil
        case .failure:
            status = .failure
            detailText = L10n.Snabble.PaymentStatus.Payment.error
            actionTitle = L10n.Snabble.PaymentStatus.Payment.tryAgain
        case .success:
            status = .success
            detailText = nil
            actionTitle = nil
        }

        text = L10n.Snabble.PaymentStatus.Payment.title
        image = nil
    }

    init(text: String, actionTitle: String? = nil) {
        self.text = text
        self.actionTitle = actionTitle

        status = nil
        detailText = nil
        image = nil
    }
}
