//
//  RawPaymentMethod+Auth.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import LocalAuthentication

extension RawPaymentMethod {
    func isAddingAllowed(showAlertOn viewController: UIViewController) -> Bool {
        if self.codeRequired && !devicePasscodeSet() {
            let mode = BiometricAuthentication.supportedBiometry
            let msg = mode == .none ?
                L10n.Snabble.PaymentMethods.NoCodeAlert.noBiometry
                : L10n.Snabble.PaymentMethods.NoCodeAlert.biometry

            let alert = UIAlertController(title: L10n.Snabble.PaymentMethods.noDeviceCode,
                                          message: msg,
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default, handler: nil))
            viewController.present(alert, animated: true)
            return false
        } else {
            return true
        }
    }

    // checks if the device passcode and/or biometry is enabled
    private func devicePasscodeSet() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
}
