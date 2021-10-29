//
//  CheckoutStepsViewModel.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 13.10.21.
//

import Foundation

class CheckoutStepsViewModel {
    var headerViewModel: CheckoutHeaderViewModel {
        CheckoutStepStatus.success
    }

    var steps: [PaymentStatus] {
        [
            .loading, .success, .failure, .failure
        ]
    }
}

enum PaymentStatus: Hashable {
    case loading
    case success
    case failure
}
