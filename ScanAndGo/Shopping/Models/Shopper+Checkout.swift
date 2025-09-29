//
//  Shopper+Checkout.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 27.06.24.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding

extension ShoppingCart {
    func taxationInfoRequired() -> Bool {
        if let taxationInfoRequired = requiredInformation.first(where: { $0.id == .taxation }) {
            return taxationInfoRequired.value == nil
        }
        return false
    }
}
extension Shopper {
    public func sendAction(_ actionType: ActionType) {
        ActionManager.shared.actionPublisher.send(actionType)
    }
    
    func startCheckout() {
        guard let paymentMethod = self.paymentManager.selectedPayment?.method else {
            logger.debug("selectedPayment method is nil")
            return
        }
        
        let paymentDetail = self.paymentManager.selectedPayment?.detail
        let shoppingCart = barcodeManager.shoppingCart
        
        if  paymentDetail == nil {
            logger.debug("selectedPayment detail is nil")
        }
        self.processing = true
        
        self.barcodeManager.shoppingCart.createCheckoutInfo(barcodeManager.project, timeout: 10) { result in
            Task { @MainActor in
                self.processing = false

                switch result {
                case .success(let info):
                    // force any required info to be re-requested on the next attempt
                    shoppingCart.resetInformationData() // requiredInformationData = []

                    let detail = self.paymentManager.selectedPayment?.detail
                    self.gotoPayment(paymentMethod, detail, info, shoppingCart) { didStart in
                        if !didStart {
                            self.startScanner()
                        }
                    }
                case .failure(let error):
                    let handled = self.handleCheckoutError(error)
                    if !handled {
                        if let offendingSkus = error.details?.compactMap({ $0.sku }) {
                            self.showProductError(offendingSkus)
                            return
                        }

                        if paymentMethod.offline {
                            // if the payment method works offline, ignore the error and continue anyway
                            let info = SignedCheckoutInfo([paymentMethod])
                            self.gotoPayment(paymentMethod, nil, info, self.barcodeManager.shoppingCart) { _ in }
                            return
                        }

                        if case SnabbleError.urlError = error {
                            self.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.offlineHint"))
                            return
                        }

                        switch error.type {
                        case .noAvailableMethod:
                            self.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.noMethodAvailable"))
                        default:
                            self.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.errorStarting"))
                        }
                    }
                }
            }
        }
        
    }
    
    private func showProductError(_ skus: [String]) {
        var offendingProducts = [String]()
        for sku in skus {
            if let item = self.barcodeManager.shoppingCart.items.first(where: { $0.product.sku == sku }) {
                offendingProducts.append(item.product.name)
            }
        }
        
        let start = Asset.localizedString(forKey: offendingProducts.count == 1
                                          ? "Snabble.SaleStop.ErrorMsg.one"
                                          : "Snabble.SaleStop.errorMsg"
        )
        let msg = start + "\n\n" + offendingProducts.joined(separator: "\n")
        errorMessage = msg
    }
}
