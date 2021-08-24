//
//  RawPaymentMethod+UI.swift
//
//  Copyright © 2021 snabble. All rights reserved.
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
            return L10n.Snabble.Payment.payAtSCO
        case .paydirektOneKlick:
            return "paydirekt"
        case .qrCodePOS, .qrCodeOffline:
            return L10n.Snabble.Payment.payAtCashDesk
        case .externalBilling:
            return L10n.Snabble.Payment.payViaInvoice
        case .customerCardPOS:
            return L10n.Snabble.Payment.payUsingCustomerCard
        case .applePay:
            return "Apple Pay"
        case .twint:
            return "TWINT"
        case .postFinanceCard:
            return "PostFinance Card"
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
        case .applePay: return UIImage.fromBundle("SnabbleSDK/payment/payment-apple-pay")
        case .twint: return UIImage.fromBundle("SnabbleSDK/payment/payment-twint")
        case .postFinanceCard: return UIImage.fromBundle("SnabbleSDK/payment/payment-postfinance")
        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return UIImage.fromBundle("SnabbleSDK/payment/payment-pos")
        }
    }

    func editViewController(with projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        switch self {
        case .deDirectDebit:
            return SepaEditViewController(nil, analyticsDelegate)
        case .paydirektOneKlick:
            return PaydirektEditViewController(nil, analyticsDelegate)
        case .creditCardMastercard, .creditCardVisa, .creditCardAmericanExpress:
            return creditCardEditViewController(projectId, analyticsDelegate)
        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS, .gatekeeperTerminal, .applePay:
            break
        case .twint, .postFinanceCard:
            if let projectId = projectId {
                return SnabbleAPI.methodRegistry.createEntry(method: self, projectId, analyticsDelegate)
            }
        }

        return nil
    }

    private func creditCardEditViewController(_ projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard
            let projectId = projectId,
            let project = SnabbleAPI.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self })
        else {
            return nil
        }

        if descriptor.acceptedOriginTypes?.contains(.ipgHostedDataID) == true {
            return CreditCardEditViewController(brand: CreditCardBrand.forMethod(self), projectId, analyticsDelegate)
        } else if descriptor.acceptedOriginTypes?.contains(.datatransCreditCardAlias) == true {
            return SnabbleAPI.methodRegistry.createEntry(method: self, projectId, analyticsDelegate)
        }

        return nil
    }
}
