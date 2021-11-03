//
//  CheckoutStepStatus.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 04.10.21.
//

import Foundation

enum CheckoutStepStatus: Hashable {
    case loading
    case success
    case failure
}

extension CheckoutStepStatus {
    static func from(fulfillmentState: FulfillmentState) -> Self {
        switch fulfillmentState {
        case .unknown, .aborted, .allocationFailed, .allocationTimedOut, .failed:
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
