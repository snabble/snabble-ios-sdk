//
//  ShoppingModel+Payment.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 23.06.24.
//

import UIKit

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleTheme
import SnabblePayment

extension Shopper {
    var project: Project {
        barcodeManager.project
    }
}

extension Shopper: PaymentMethodManagerDelegate {

    private func setAlertProvider(_ provider: AlertProviding) {
        let alertController = provider.alertController { _ in }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            sendAction(.alert(alert(alertController)))
        }
    }
    
    private func acceptPayment(method: RawPaymentMethod?, detail: PaymentMethodDetail?) -> Bool {
        !(method?.dataRequired == true && detail == nil)
    }
    
    func verifyPayment(_ payment: Payment?) {
        guard let payment = paymentManager.selectedPayment, !restrictedPayments.contains(payment.method) else {
            hasValidPayment = false
            logger.debug("didSelectPayment failed: \(payment.debugDescription)")
            return
        }
        hasValidPayment = acceptPayment(method: payment.method, detail: payment.detail)
    }
    
    public func paymentMethodManager(didSelectItem item: PaymentMethodItem) {
        logger.debug("didSelectItem: \(item.title)")
        guard item.selectable else {
            return
        }
        let method = item.method
        let detail = item.methodDetail
        
        guard !restrictedPayments.contains(method) else {
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                sendAction(.alert(
                    Alert(title: Text(Asset.localizedString(forKey: "Snabble.Payment.Unavailable.title")),
                          message: Text(Asset.localizedString(forKey: "Snabble.Payment.Unavailable.message")))
                ))
                paymentManager.selectedPayment = nil
            }
            return
        }
        // If the payment method requires private data and no password and/or biometry is set, it cannot be used.
        if detail == nil, !method.isAddingAllowed {
            setAlertProvider(method)
            return
        }
        
        // if the selected method is missing its detail data, immediately open the edit VC for the method
        if detail == nil,
           let controller = method.editViewController(with: project.id, self) {
            self.navigationItem = NavigationItem(viewController: controller)
        } else if method == .applePay && !ApplePay.canMakePayments(with: project.id) {
            ApplePay.openPaymentSetup()
        }
    }
    
    public func paymentMethodManager(didSelectPayment payment: SnabbleCore.Payment?) {
        verifyPayment(payment)
    }
}

extension Shopper: PaymentDelegate {
    public func checkoutFinished(_ cart: SnabbleCore.ShoppingCart, _ process: SnabbleCore.CheckoutProcess?) {
        logger.debug("checkout finished with state: \(process?.paymentState.rawValue ?? "unknown")")
        self.navigationItem = nil
        let success: Bool

        if let paymentState = process?.paymentState {
            success = PaymentState.successStates.contains(paymentState)
        } else {
            success = false
        }
        
        // Notify the host app that the checkout session is complete. Called here (not in
        // navigationItem.didSet) so that spurious SwiftUI binding write-backs during
        // UIKit modal presentation do not trigger premature tab switches.
        Task { @MainActor in self.onCheckoutCompleted?(success) }
    }

    public func paymentRequiresNavigation(to viewController: UIViewController) {
        logger.debug("paymentRequiresNavigation: \(String(describing: type(of: viewController)))")
        replaceController(with: viewController)
    }
    
    public var view: UIView! {
        UIView()
    }
    
    public func exitToken(_ exitToken: SnabbleCore.ExitToken, for shop: SnabbleCore.Shop) {
        logger.debug("exitToken \(exitToken.value ?? "n/a")")
    }
}
