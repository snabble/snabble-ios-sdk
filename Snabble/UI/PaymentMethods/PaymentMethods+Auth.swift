//
//  PaymentMethods+Auth.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import LocalAuthentication

extension RawPaymentMethod {
    func isAddingAllowed(showAlertOn viewController: UIViewController) -> Bool {
        if self.codeRequired && !devicePasscodeSet() {
            let mode = BiometricAuthentication.supportedBiometry
            let msg = mode == .none ?
                "Snabble.PaymentMethods.noCodeAlert.noBiometry".localized()
                : "Snabble.PaymentMethods.noCodeAlert.biometry".localized()

            let alert = UIAlertController(title: "Snabble.PaymentMethods.noDeviceCode".localized(),
                                          message: msg,
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default, handler: nil))
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
