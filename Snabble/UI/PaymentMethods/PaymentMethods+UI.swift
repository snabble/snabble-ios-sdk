//
//  PaymentMethods+UI.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

extension PaymentMethodDetail {
    var icon: UIImage? {
        switch self.methodData {
        case .tegutEmployeeCard:
            return UIImage.fromBundle("SnabbleSDK/payment/payment-tegut")
        default:
            return self.rawMethod.icon
        }
    }
}

extension RawPaymentMethod {
    public var displayName: String {
        switch self {
        case .deDirectDebit:
            return "SEPA-Lastschrift"
        case .creditCardMastercard:
            return "Mastercard"
        case .creditCardVisa:
            return "VISA"
        case .creditCardAmericanExpress:
            return "American Express"
        case .gatekeeperTerminal:
            return "Snabble.Payment.payAtSCO".localized()
        case .paydirektOneKlick:
            return "paydirekt"
        case .qrCodePOS, .qrCodeOffline:
            return "Snabble.Payment.payAtCashDesk".localized()
        case .externalBilling:
            return "Snabble.Payment.payViaInvoice".localized()
        case .customerCardPOS:
            return "Snabble.Payment.payUsingCustomerCard".localized()
        }
    }

    public var icon: UIImage? {
        switch self {
        case .deDirectDebit: return UIImage.fromBundle("SnabbleSDK/payment/payment-sepa")
        case .creditCardVisa: return UIImage.fromBundle("SnabbleSDK/payment/payment-visa")
        case .creditCardMastercard: return UIImage.fromBundle("SnabbleSDK/payment/payment-mastercard")
        case .creditCardAmericanExpress: return UIImage.fromBundle("SnabbleSDK/payment/payment-amex")
        case .gatekeeperTerminal: return UIImage.fromBundle("SnabbleSDK/payment/payment-sco")
        case .paydirektOneKlick: return UIImage.fromBundle("SnabbleSDK/payment/payment-paydirekt")

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return UIImage.fromBundle("SnabbleSDK/payment/payment-pos")
        }
    }

    func editViewController(with projectId: Identifier<Project>?, showFromCart: Bool, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        switch self {
        case .deDirectDebit:
            return SepaEditViewController(nil, showFromCart, analyticsDelegate)
        case .paydirektOneKlick:
            return PaydirektEditViewController(nil, showFromCart, analyticsDelegate)

        case .creditCardMastercard:
            if let projectId = projectId {
                return CreditCardEditViewController(brand: .mastercard, projectId, showFromCart, analyticsDelegate)
            }
        case .creditCardVisa:
            if let projectId = projectId {
                return CreditCardEditViewController(brand: .visa, projectId, showFromCart, analyticsDelegate)
            }
        case .creditCardAmericanExpress:
            if let projectId = projectId {
                return CreditCardEditViewController(brand: .amex, projectId, showFromCart, analyticsDelegate)
            }

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS, .gatekeeperTerminal:
            ()
        }
        return nil
    }
}
