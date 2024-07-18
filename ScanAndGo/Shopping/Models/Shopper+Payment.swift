//
//  ShoppingModel+Payment.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 23.06.24.
//

import UIKit

import SwiftUI
import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

extension Shopper {
    var project: Project {
        barcodeManager.project
    }
}

extension Shopper: PaymentMethodManagerDelegate {
    
    private func setAlertProvider(_ provider: AlertProviding) {
        let alertController = provider.alertController { _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.sendAction(.alert(self.alert(alertController)))
        }
    }

    private func acceptPayment(method: RawPaymentMethod?, detail: PaymentMethodDetail?) -> Bool {
        !(method?.dataRequired == true && detail == nil)
    }
    
    public func paymentMethodManager(didSelectItem item: SnabbleUI.PaymentMethodItem) {
        logger.debug("didSelectItem: \(item.title)")
        guard item.selectable else {
            return
        }
        let method = item.method
        let detail = item.methodDetail

        guard !restrictedPayments.contains(method) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.sendAction(.alert(
                    Alert(title: Text("Entschuldigung"),
                          message: Text("Diese Zahlungsmethode ist zur Zeit nicht verfügbar."))
                ))
            }
            return
        }
        // If the payment method requires private data and no password and/or biometry is set, it cannot be used.
        if detail == nil, !method.isAddingAllowed {
            setAlertProvider(method)
            return
        }
        
        if detail != nil, let payment = paymentManager.selectedPayment {
            selectedPayment = payment
        }
        // if the selected method is missing its detail data, immediately open the edit VC for the method
        if detail == nil,
            let controller = method.editViewController(with: project.id, self) {
            self.controller = controller
        } else if method == .applePay && !ApplePay.canMakePayments(with: project.id) {
            ApplePay.openPaymentSetup()
        } else if acceptPayment(method: method, detail: detail), let payment = paymentManager.selectedPayment {
            selectedPayment = payment
        }
    }
    
    public func paymentMethodManager(didSelectPayment payment: SnabbleCore.Payment?) {
        logger.debug("didSelectPayment: \(payment.debugDescription)")
        let payment = paymentManager.selectedPayment
        
        let method = payment?.method
        let detail = payment?.detail

        // Payment is already configured
        if method?.dataRequired == true && detail != nil {
            selectedPayment = payment
        }
    }
}

extension Shopper: PaymentDelegate {
    public func checkoutFinished(_ cart: SnabbleCore.ShoppingCart, _ process: SnabbleCore.CheckoutProcess?) {
        logger.debug("checkout finished")
//        let paymentState = process?.paymentState
//        if paymentState == .successful || paymentState == .transferred {
//        }
    }
    
    public var view: UIView! {
        UIView()
    }
    
    public func exitToken(_ exitToken: SnabbleCore.ExitToken, for shop: SnabbleCore.Shop) {
        logger.debug("exitToken \(exitToken.value ?? "n/a")")
    }
}
