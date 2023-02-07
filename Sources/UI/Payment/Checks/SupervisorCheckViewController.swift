//
//  SupervisorCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

final class SupervisorCheckViewController: BaseCheckViewController {
    override func renderCode(_ content: String) -> UIImage? {
        PDF417.generate(for: content, scale: 2)
    }

    // supervisors are only concerned with checks: if there are failed checks, bail out,
    // and if all checks pass, finalize the checkout
    override func checkContinuation(for process: CheckoutProcess) -> CheckModel.CheckResult {
        if process.hasFailedChecks {
            return .rejectCheckout
        }

        if process.allChecksSuccessful {
            return .finalizeCheckout
        }

        return .continuePolling
    }

    override func arrangeLayout() {
        if let iconWrapper = iconWrapper,
           let textWrapper = textWrapper,
           let idWrapper = idWrapper,
           let codeWrapper = codeWrapper {
            stackView?.addArrangedSubview(iconWrapper)
            stackView?.addArrangedSubview(textWrapper)
            stackView?.addArrangedSubview(codeWrapper)
            stackView?.addArrangedSubview(idWrapper)
        }
    }
}
