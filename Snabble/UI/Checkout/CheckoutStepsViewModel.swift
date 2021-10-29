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

    var steps: [CheckoutStepViewModel] {
        [
            CheckoutStepView.Mock.Payment.loading,
            CheckoutStepView.Mock.Payment.success,
            CheckoutStepView.Mock.Payment.failure,
            CheckoutStepView.Mock.Payment.failure
        ]
    }
}
