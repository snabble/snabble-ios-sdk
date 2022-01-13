//
//  SupervisorCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

final class SupervisorCheckViewController: BaseCheckViewController {
    override func renderCode(_ content: String) -> UIImage? {
        PDF417.generate(for: content, scale: 2)
    }

    override func checkContinuation(for process: CheckoutProcess) -> CheckResult {
        if process.hasFailedChecks {
            return .rejectCheckout
        }

        if process.allChecksSuccessful {
            return .finalizeCheckout
        }

        return .continuePolling
    }

    override func arrangeLayout() {
        let stackWrapper = UIView()
        stackWrapper.translatesAutoresizingMaskIntoConstraints = false
        stackWrapper.addSubview(stackView)

        idWrapper.translatesAutoresizingMaskIntoConstraints = false
        codeWrapper.translatesAutoresizingMaskIntoConstraints = false
        topWrapper.addSubview(stackWrapper)
        topWrapper.addSubview(idWrapper)
        topWrapper.addSubview(codeWrapper)

        NSLayoutConstraint.activate([
            stackWrapper.topAnchor.constraint(equalTo: topWrapper.topAnchor),
            stackWrapper.leadingAnchor.constraint(equalTo: topWrapper.leadingAnchor),
            stackWrapper.trailingAnchor.constraint(equalTo: topWrapper.trailingAnchor),
            stackWrapper.bottomAnchor.constraint(equalTo: codeWrapper.topAnchor, constant: -4),

            idWrapper.bottomAnchor.constraint(equalTo: topWrapper.bottomAnchor, constant: -4),
            idWrapper.leadingAnchor.constraint(equalTo: topWrapper.leadingAnchor),
            idWrapper.trailingAnchor.constraint(equalTo: topWrapper.trailingAnchor),

            codeWrapper.bottomAnchor.constraint(equalTo: idWrapper.topAnchor),
            codeWrapper.leadingAnchor.constraint(equalTo: topWrapper.leadingAnchor),
            codeWrapper.trailingAnchor.constraint(equalTo: topWrapper.trailingAnchor),

            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackWrapper.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackWrapper.bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackWrapper.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: stackWrapper.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: stackWrapper.trailingAnchor, constant: -16)
        ])

        stackView.addArrangedSubview(iconWrapper)
        stackView.addArrangedSubview(textWrapper)
    }
}
