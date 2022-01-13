//
//  GatekeeperCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

final class GatekeeperCheckViewController: BaseCheckViewController {
    override func renderCode(_ content: String) -> UIImage? {
        return QRCode.generate(for: content, scale: 5)
    }

    override func checkContinuation(for process: CheckoutProcess) -> CheckResult {
        if process.hasFailedChecks {
            return .rejectCheckout
        }

        if process.paymentState == .pending {
            return .continuePolling
        }

        if process.allChecksSuccessful {
            return .finalizeCheckout
        }

        return .continuePolling
    }

    override func arrangeLayout() {
        topWrapper.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topWrapper.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: topWrapper.bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: topWrapper.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: topWrapper.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: topWrapper.trailingAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(iconWrapper)
        stackView.addArrangedSubview(textWrapper)
        stackView.addArrangedSubview(arrowWrapper)
        stackView.addArrangedSubview(codeWrapper)
        stackView.addArrangedSubview(idWrapper)
    }
}
