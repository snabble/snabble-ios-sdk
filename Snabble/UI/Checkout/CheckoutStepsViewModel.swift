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

    var steps: [CheckoutStep] {
        [
            .init(paymentStatus: .loading),
            .init(paymentStatus: .failure),
            .init(paymentStatus: .success),
            .init(
                text: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
            ),
            .init(
                text: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.",
                actionTitle: "Erneut versuchen"
            )
        ]
    }
}

enum PaymentStatus: Hashable {
    case loading
    case success
    case failure
}
