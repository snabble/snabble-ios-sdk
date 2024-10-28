//
//  RawPaymentMethod+UI.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

extension PaymentMethodDetail {
    public var icon: UIImage? {
        return Asset.image(named: "SnabbleSDK/payment/" + self.imageName)
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
        case .giropayOneKlick:
            return "giropay"
        case .qrCodePOS, .qrCodeOffline:
            return Asset.localizedString(forKey: "Snabble.Payment.payAtCashDesk")
        case .externalBilling:
            return Asset.localizedString(forKey: "Snabble.Payment.ExternalBilling.title")
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
        return Asset.image(named: "SnabbleSDK/payment/" + self.imageName)
    }

    public func editViewController(with projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        switch self {
        case .deDirectDebit:
            return sepaEditViewController(projectId, analyticsDelegate)
        case .giropayOneKlick:
            return GiropayEditViewController(nil, for: projectId, with: analyticsDelegate)
        case .creditCardMastercard, .creditCardVisa, .creditCardAmericanExpress:
            return creditCardEditViewController(projectId, analyticsDelegate)
        case .externalBilling:
            return externalBillingEditViewController(projectId, analyticsDelegate)
        case .qrCodePOS, .qrCodeOffline, .customerCardPOS, .gatekeeperTerminal, .applePay:
            break
        case .twint, .postFinanceCard:
            if let projectId = projectId {
                return Snabble.methodRegistry.createEntry(method: self, projectId, analyticsDelegate)
            }
        }

        return nil
    }
    
    private func externalBillingEditViewController(_ projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard
            let projectId = projectId,
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self })
        else {
            return nil
        }
        if descriptor.acceptedOriginTypes?.contains(.contactPersonCredentials) == true {
            let model = InvoiceLoginProcessor(invoiceLoginModel: InvoiceLoginModel(project: project))
            
            return InvoiceViewController(viewModel: model)
        }
        return nil
    }

    private func sepaEditViewController(_ projectId: Identifier<Project>?, _ analyticsDelegate: AnalyticsDelegate?) -> UIViewController? {
        guard
            let projectId = projectId,
            let project = Snabble.shared.project(for: projectId),
            let descriptor = project.paymentMethodDescriptors.first(where: { $0.id == self })
        else {
            return nil
        }
        if descriptor.acceptedOriginTypes?.contains(.payoneSepaData) == true {
            return SepaDataEditViewController(viewModel: SepaDataModel(projectId: projectId))
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
            let creditCardViewController = TeleCashCreditCardAddViewController(brand: CreditCardBrand.forMethod(self), projectId: projectId)
            let viewController = UserPaymentViewController(
                fields: creditCardViewController.defaultUserFields,
                requiredFields: creditCardViewController.requiredUserFields
            )
            viewController.nextViewController = creditCardViewController
            return viewController
        } else if descriptor.acceptedOriginTypes?.contains(.payonePseudoCardPAN) == true {
            return PayoneCreditCardEditViewController(brand: CreditCardBrand.forMethod(self), prefillData: Snabble.shared.userProvider?.getUser(), projectId)
        } else if descriptor.acceptedOriginTypes?.contains(.datatransCreditCardAlias) == true {
            let controller = Snabble.methodRegistry.createEntry(method: self, projectId, analyticsDelegate)
            if let userValidation = controller as? UserInputConformance {
                let viewController = UserPaymentViewController(
                    fields: userValidation.defaultUserFields,
                    requiredFields: userValidation.requiredUserFields
                )
                viewController.nextViewController = userValidation
                return viewController
            } else {
                return controller
            }
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
                .giropayOneKlick,
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
