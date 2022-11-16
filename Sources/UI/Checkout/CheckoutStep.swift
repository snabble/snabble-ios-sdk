//
//  CheckoutStep.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 29.10.21.
//

import Foundation
import UIKit
import SnabbleCore

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
            detailText = Asset.localizedString(forKey: "Snabble.PaymentStatus.Payment.error")
            actionTitle = nil
        case .pending, .processing, .transferred:
            status = .loading
            detailText = nil
            actionTitle = nil
        case .successful:
            status = .success
            detailText = nil
            actionTitle = nil
        }
        text = Asset.localizedString(forKey: "Snabble.PaymentStatus.Payment.title")
        image = nil
    }
}

extension CheckoutStep {
    init(fulfillment: Fulfillment, paymentState: PaymentState) {
        status = paymentState == .failed ? .aborted : .from(fulfillmentState: fulfillment.state)
        text = fulfillment.displayName
        image = nil
        detailText = fulfillment.detailText(for: status!)
        actionTitle = nil
    }

    init(exitToken: ExitToken, paymentState: PaymentState) {
        status = paymentState == .failed ? .aborted : .from(exitToken: exitToken)
        text = Asset.localizedString(forKey: "Snabble.PaymentStatus.ExitCode.title")
        image = exitToken.image
        detailText = image != nil ? Asset.localizedString(forKey: "Snabble.PaymentStatus.ExitCode.openExitGateTimed") : nil
        actionTitle = nil
    }

    init(receiptLink: Link, paymentState: PaymentState) {
        status = paymentState == .failed ? .aborted : .success
        text = Asset.localizedString(forKey: "Snabble.PaymentStatus.Receipt.title")
        image = nil
        detailText = nil
        actionTitle = nil
    }

    init(originCandidate: OriginCandidate, savedIbans: Set<String>) {
        status = nil
        if let origin = originCandidate.origin, !savedIbans.contains(origin) {
            text = Asset.localizedString(forKey: "Snabble.SEPA.IbanTransferAlert.message", arguments: origin)
            actionTitle = Asset.localizedString(forKey: "Snabble.PaymentStatus.AddDebitCard.button")
        } else {
            text = Asset.localizedString(forKey: "Snabble.PaymentStatus.DebitCardAdded.message")
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
            return Asset.localizedString(forKey: "Snabble.PaymentStatus.Tobacco.title")
        default:
            return Asset.localizedString(forKey: "Snabble.PaymentStatus.Fulfillment.title")
        }
    }

    func detailText(for status: CheckoutStepStatus) -> String? {
        switch type {
        case "tobaccolandEWA":
            switch status {
            case .loading, .aborted:
                return nil
            case .success:
                return Asset.localizedString(forKey: "Snabble.PaymentStatus.Tobacco.message")
            case .failure:
                return Asset.localizedString(forKey: "Snabble.PaymentStatus.Tobacco.error")
            }
        default:
            return nil
        }
    }
}
