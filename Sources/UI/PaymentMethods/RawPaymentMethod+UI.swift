//
//  RawPaymentMethod+UI.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SwiftUI
import SnabbleCore

extension PaymentMethodDetail {
    var icon: UIImage? {
        switch self.methodData {
        case .tegutEmployeeCard:
            return Asset.image(named: "SnabbleSDK/payment/payment-tegut")
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
            return Asset.localizedString(forKey: "Snabble.Payment.payAtSCO")
        case .paydirektOneKlick:
            return "paydirekt"
        case .qrCodePOS, .qrCodeOffline:
            return Asset.localizedString(forKey: "Snabble.Payment.payAtCashDesk")
        case .externalBilling:
            return Asset.localizedString(forKey: "Snabble.Payment.payViaInvoice")
        case .customerCardPOS:
            return Asset.localizedString(forKey: "Snabble.Payment.payUsingCustomerCard")
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
        case .deDirectDebit:
            return Asset.image(named: "SnabbleSDK/payment/payment-sepa")
        case .creditCardVisa:
            return Asset.image(named: "SnabbleSDK/payment/payment-visa")
        case .creditCardMastercard: return Asset.image(named: "SnabbleSDK/payment/payment-mastercard")
        case .creditCardAmericanExpress: return Asset.image(named: "SnabbleSDK/payment/payment-amex")
        case .gatekeeperTerminal: return Asset.image(named: "SnabbleSDK/payment/payment-sco")
        case .paydirektOneKlick: return Asset.image(named: "SnabbleSDK/payment/payment-paydirekt")
        case .applePay: return Asset.image(named: "SnabbleSDK/payment/payment-apple-pay")
        case .twint: return Asset.image(named: "SnabbleSDK/payment/payment-twint")
        case .postFinanceCard: return Asset.image(named: "SnabbleSDK/payment/payment-postfinance")
        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS:
            return Asset.image(named: "SnabbleSDK/payment/payment-pos")
        }
    }

    func editViewController(with projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        switch self {
        case .deDirectDebit:
//            return SepaEditViewController(nil, analyticsDelegate)
            return sepaEditViewController(projectId, analyticsDelegate)

        case .paydirektOneKlick:
            return PaydirektEditViewController(nil, for: projectId, with: analyticsDelegate)
        case .creditCardMastercard, .creditCardVisa, .creditCardAmericanExpress:
            return creditCardEditViewController(projectId, analyticsDelegate)
        case .qrCodePOS, .qrCodeOffline, .externalBilling, .customerCardPOS, .gatekeeperTerminal, .applePay:
            break
        case .twint, .postFinanceCard:
            if let projectId = projectId {
                return Snabble.methodRegistry.createEntry(method: self, projectId, analyticsDelegate)
            }
        }

        return nil
    }
    
    private func sepaEditViewController(_ projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController?  {
        guard
            let projectId = projectId,
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self })
        else {
            return nil
        }
        if descriptor.acceptedOriginTypes?.contains(.payoneSepaData) == true {
            return SepaDataEditViewController(viewModel: SepaDataModel())
        } else {
            return SepaEditViewController(nil, analyticsDelegate)
        }
    }
    
    private func creditCardEditViewController(_ projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard
            let projectId = projectId,
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self })
        else {
            return nil
        }

        if descriptor.acceptedOriginTypes?.contains(.ipgHostedDataID) == true {
            return TeleCashCreditCardEditViewController(brand: CreditCardBrand.forMethod(self), projectId, analyticsDelegate)
        } else if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
            return PayoneCreditCardEditViewController(brand: CreditCardBrand.forMethod(self), projectId, analyticsDelegate)
        } else if descriptor.acceptedOriginTypes?.contains(.datatransCreditCardAlias) == true {
            return Snabble.methodRegistry.createEntry(method: self, projectId, analyticsDelegate)
        }

        return nil
    }

    func checkoutDisplayViewController(shop: Shop,
                                       checkoutProcess: CheckoutProcess?,
                                       shoppingCart: ShoppingCart,
                                       delegate: PaymentDelegate?) -> UIViewController? {
        if !self.offline && checkoutProcess == nil {
            return nil
        }

        let paymentDisplay: UIViewController
        switch self {
        case .qrCodePOS:
            let qrCheckout = QRCheckoutViewController(shop: shop,
                                                      checkoutProcess: checkoutProcess!,
                                                      cart: shoppingCart)
            qrCheckout.delegate = delegate
            paymentDisplay = qrCheckout
        case .qrCodeOffline:
            if let codeConfig = shop.project?.qrCodeConfig {
                let embedded = EmbeddedCodesCheckoutViewController(shop: shop,
                                                                   checkoutProcess: checkoutProcess,
                                                                   cart: shoppingCart,
                                                                   qrCodeConfig: codeConfig)
                embedded.delegate = delegate
                paymentDisplay = embedded
            } else {
                return nil
            }
        case .applePay:
            let applePay = ApplePayCheckoutViewController(shop: shop,
                                                          checkoutProcess: checkoutProcess!,
                                                          cart: shoppingCart)
            applePay.delegate = delegate
            paymentDisplay = applePay
        case .customerCardPOS:
            let customerCart = CustomerCardCheckoutViewController(shop: shop,
                                                                  checkoutProcess: checkoutProcess!,
                                                                  cart: shoppingCart)
            customerCart.delegate = delegate
            paymentDisplay = customerCart
        case .deDirectDebit,
                .creditCardVisa,
                .creditCardMastercard,
                .creditCardAmericanExpress,
                .externalBilling,
                .paydirektOneKlick,
                .twint,
                .postFinanceCard,
                .gatekeeperTerminal:
            let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess!)
            checkoutSteps.paymentDelegate = delegate
            paymentDisplay = checkoutSteps
        }
        paymentDisplay.hidesBottomBarWhenPushed = true

        return paymentDisplay
    }
}
