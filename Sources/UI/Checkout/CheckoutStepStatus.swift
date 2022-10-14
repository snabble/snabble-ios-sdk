//
//  CheckoutStepStatus.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation
import SnabbleCore

enum CheckoutStepStatus: Hashable {
    case loading
    case success
    case failure
    case aborted
}

extension CheckoutStepStatus {
    static func from(fulfillmentState: FulfillmentState) -> Self {
        switch fulfillmentState {
        case .aborted:
            return .aborted
        case .unknown, .allocationFailed, .allocationTimedOut, .failed:
            return .failure
        case .open, .processing, .allocating:
            return .loading
        case .allocated, .processed:
            return .success
        }
    }
}

extension CheckoutStepStatus {
    static func from(paymentState: PaymentState) -> Self {
        switch paymentState {
        case .processing, .transferred, .pending:
            return .loading
        case .successful:
            return .success
        case .failed, .unauthorized, .unknown:
            return .failure
        }
    }
}

extension CheckoutStepStatus {
    static func from(exitToken: ExitToken) -> Self {
        guard exitToken.value != nil else {
            return .loading
        }
        return .success
    }
}

extension Array where Element == CheckoutStep {
    var checkoutStepStatus: CheckoutStepStatus {
        if contains(where: { $0.status == .failure }) {
            return .failure
        }

        if contains(where: { $0.status == .aborted }) {
            return .aborted
        }

        if contains(where: { $0.status == .loading }) {
            return .loading
        }

        return .success
    }
}
