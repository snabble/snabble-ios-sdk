//
//  RawPaymentMethod+Auth.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import LocalAuthentication
import SnabbleCore
import SnabbleAssetProviding

extension RawPaymentMethod: AlertProviding {
    public func alertController(_ onDismiss: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let mode = BiometricAuthentication.supportedBiometry
        let msg = mode == .none ?
            Asset.localizedString(forKey: "Snabble.PaymentMethods.NoCodeAlert.noBiometry")
            : Asset.localizedString(forKey: "Snabble.PaymentMethods.NoCodeAlert.biometry")

        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.PaymentMethods.noDeviceCode"),
                                      message: msg,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: onDismiss))
        return alert
    }
}

extension RawPaymentMethod {
    public var isAddingAllowed: Bool {
        return self.codeRequired && !devicePasscodeSet() ? false : true
    }
    
    @MainActor
    func isAddingAllowed(showAlertOn viewController: UIViewController) -> Bool {
        if !isAddingAllowed {
            let alert = self.alertController(nil)
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
