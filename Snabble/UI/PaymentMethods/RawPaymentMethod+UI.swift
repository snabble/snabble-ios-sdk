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
            return Asset.SnabbleSDK.Payment.paymentTegut.image
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
        case .deDirectDebit: return Asset.SnabbleSDK.Payment.paymentSepa.image
        case .creditCardVisa: return Asset.SnabbleSDK.Payment.paymentVisa.image
        case .creditCardMastercard: return Asset.SnabbleSDK.Payment.paymentMastercard.image
        case .creditCardAmericanExpress: return Asset.SnabbleSDK.Payment.paymentAmex.image
        case .gatekeeperTerminal: return Asset.SnabbleSDK.Payment.paymentSco.image
        case .paydirektOneKlick: return Asset.SnabbleSDK.Payment.paymentPaydirekt.image
        case .applePay: return Asset.SnabbleSDK.Payment.paymentApplePay.image
        case .twint: return Asset.SnabbleSDK.Payment.paymentTwint.image
        case .postFinanceCard: return Asset.SnabbleSDK.Payment.paymentPostfinance.image
        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return Asset.SnabbleSDK.Payment.paymentPos.image
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
            return TeleCashCreditCardEditViewController(brand: CreditCardBrand.forMethod(self), projectId, analyticsDelegate)
        } else if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
            return PayoneCreditCardEditViewController(brand: CreditCardBrand.forMethod(self), projectId, analyticsDelegate)
        } else if descriptor.acceptedOriginTypes?.contains(.datatransCreditCardAlias) == true {
            return SnabbleAPI.methodRegistry.createEntry(method: self, projectId, analyticsDelegate)
        }

        return nil
    }

    func checkoutDisplayViewController(shop: Shop,
                                       checkoutProcess: CheckoutProcess?,
                                       shoppingCart: ShoppingCart,
                                       delegate: PaymentDelegate?) -> UIViewController? {
        let paymentDisplay: UIViewController
        switch self {
        case .qrCodePOS:
            paymentDisplay = QRCheckoutViewController(checkoutProcess!, shoppingCart, delegate)
        case .qrCodeOffline:
            if let codeConfig = shop.project?.qrCodeConfig {
                paymentDisplay = EmbeddedCodesCheckoutViewController(checkoutProcess, shoppingCart, delegate, codeConfig)
            } else {
                return nil
            }
        case .applePay:
            paymentDisplay = ApplePayCheckoutViewController(checkoutProcess!, shoppingCart, shop, delegate)
        case .customerCardPOS:
            paymentDisplay = CustomerCardCheckoutViewController(checkoutProcess!, shoppingCart, delegate)
        case .deDirectDebit,
                .creditCardVisa,
                .creditCardMastercard,
                .creditCardAmericanExpress,
                .externalBilling,
                .paydirektOneKlick,
                .twint,
                .postFinanceCard,
                .gatekeeperTerminal:
            paymentDisplay = CheckoutStepsViewController(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess!)
        }
        paymentDisplay.hidesBottomBarWhenPushed = true

        return paymentDisplay
    }
}
