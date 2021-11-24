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
        lhs.image?.pngData() == rhs.image?.pngData()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(status)
        hasher.combine(text)
        hasher.combine(detailText)
        hasher.combine(actionTitle)
        hasher.combine(image?.pngData())
    }
}

extension CheckoutStep {
    init(text: String, actionTitle: String? = nil) {
        self.text = text
        self.actionTitle = actionTitle

        status = nil
        detailText = nil
        image = nil
    }
}

extension CheckoutStep {
    init(paymentState: PaymentState) {
        switch paymentState {
        case .unknown, .failed, .unauthorized:
            status = .failure
            detailText = L10n.Snabble.PaymentStatus.Payment.error
            actionTitle = L10n.Snabble.PaymentStatus.Payment.tryAgain
        case .pending, .processing, .transferred:
            status = .loading
            detailText = nil
            actionTitle = nil
        case .successful:
            status = .success
            detailText = nil
            actionTitle = nil
        }
        text = L10n.Snabble.PaymentStatus.Payment.title
        image = nil
    }
}

extension CheckoutStep {
    init(fulfillment: Fulfillment) {
        status = .from(fulfillmentState: fulfillment.state)
        text = fulfillment.displayName
        image = nil
        detailText = fulfillment.detailText
        actionTitle = nil
    }

    init(exitToken: ExitToken) {
        status = .from(exitToken: exitToken)
        text = L10n.Snabble.PaymentStatus.ExitCode.title
        image = exitToken.image
        detailText = nil
        actionTitle = nil
    }

    init(receiptLink: Link) {
        status = .success
        text = L10n.Snabble.PaymentStatus.Receipt.title
        image = nil
        detailText = nil
        actionTitle = nil
    }

    init(originCandidate: OriginCandidate, savedIbans: Set<String>) {
        status = nil
        if let origin = originCandidate.origin, savedIbans.contains(origin) {
            text = L10n.Snabble.Sepa.IbanTransferAlert.message(origin)
            actionTitle = L10n.Snabble.PaymentStatus.AddDebitCard.button
        } else {
            text = L10n.Snabble.PaymentStatus.DebitCardAdded.message
            actionTitle = nil
        }
        image = nil
        detailText = nil
    }
}

private extension Fulfillment {
    var displayName: String {
        switch type {
        case "tobaccolandEWA":
            return L10n.Snabble.PaymentStatus.Tobacco.title
        default:
            return L10n.Snabble.PaymentStatus.Fulfillment.title
        }
    }

    var detailText: String? {
        switch type {
        case "tobaccolandEWA":
            return L10n.Snabble.PaymentStatus.Tobacco.message
        default:
            return nil
        }
    }
}
