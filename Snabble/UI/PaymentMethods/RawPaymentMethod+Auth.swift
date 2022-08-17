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
                Asset.localizedString(forKey: "Snabble.PaymentMethods.NoCodeAlert.noBiometry")
                : Asset.localizedString(forKey: "Snabble.PaymentMethods.NoCodeAlert.biometry")

            let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.PaymentMethods.noDeviceCode"),
                                          message: msg,
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))
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
