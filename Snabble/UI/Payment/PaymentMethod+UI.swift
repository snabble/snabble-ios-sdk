//
//  PaymentMethod+UI.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

/// map payment methods to icons and the UIViewControllers that implement them
extension PaymentMethod {
    var dataRequired: Bool {
        switch self {
        case .deDirectDebit, .visa, .mastercard, .americanExpress,
             .externalBilling, .paydirektOneKlick, .twint, .postFinanceCard:
            return true
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS, .applePay:
            return false
        }
    }

    public func canStart() -> Bool {
        if !self.dataRequired {
            return true
        } else {
            return self.data != nil
        }
    }

    func processor(_ process: CheckoutProcess?, shop: Shop, _ cart: ShoppingCart, _ delegate: PaymentDelegate?) -> UIViewController? {
        if !self.rawMethod.offline && process == nil {
            return nil
        }
        guard self.canStart() else {
            return nil
        }

        let processor: UIViewController?
        switch self {
        case .qrCodePOS:
            processor = QRCheckoutViewController(process!, cart, delegate)
        case .qrCodeOffline:
            if let codeConfig = shop.project?.qrCodeConfig {
                processor = EmbeddedCodesCheckoutViewController(process, cart, delegate, codeConfig)
            } else {
                return nil
            }
        case .deDirectDebit, .visa, .mastercard, .americanExpress, .externalBilling, .paydirektOneKlick, .twint, .postFinanceCard:
            processor = OnlineCheckoutViewController(process!, cart, delegate)
        case .gatekeeperTerminal:
            processor = TerminalCheckoutViewController(process!, cart, delegate)
        case .applePay:
            processor = ApplePayCheckoutViewController(process!, cart, delegate)
        case .customerCardPOS:
            processor = CustomerCardCheckoutViewController(process!, cart, delegate)
        }
        processor?.hidesBottomBarWhenPushed = true

        return processor
    }

    public var displayName: String? {
        if let dataName = self.data?.displayName {
            return dataName
        }

        return self.rawMethod.displayName
    }
}
