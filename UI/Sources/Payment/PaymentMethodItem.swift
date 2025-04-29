//
//  PaymentMethodItem.swift
//  Snabble
//
//  Created by Uwe Tilemann on 20.02.25.
//

import Foundation

import SnabbleCore
import SnabbleAssetProviding

public struct PaymentMethodItem: Swift.Identifiable, PaymentPovider {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let method: RawPaymentMethod
    public let methodDetail: PaymentMethodDetail?
    public let selectable: Bool
    public let active: Bool
}

extension PaymentMethodItem {
    public static func itemsFor(
        _ method: RawPaymentMethod,
        withPaymentMethodDetails paymentMethodDetails: [PaymentMethodDetail],
        andSupportedMethods supportedMethods: [RawPaymentMethod]?
    ) -> [PaymentMethodItem] {
        let hasCartMethods = supportedMethods != nil
        let isCartMethod = supportedMethods?.contains { $0 == method } ?? false

        let paymentMethodDetails = paymentMethodDetails.filter { $0.rawMethod == method }
        let isPaymentMethodDetailAvailable = !paymentMethodDetails.isEmpty

        switch method {
        case .externalBilling, .customerCardPOS:
            if isPaymentMethodDetailAvailable {
                let items = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodItem in
                    var detailText: String?
                    if case let PaymentMethodUserData.tegutEmployeeCard(data) = paymentMethodDetail.methodData {
                        detailText = data.cardNumber
                    } else if case let PaymentMethodUserData.invoiceByLogin(data) = paymentMethodDetail.methodData {
                        detailText = LoginStrings.username.localizedString("Snabble.Payment.ExternalBilling") + ": " + data.username
                    }
                    
                    if hasCartMethods && !isCartMethod {
                        detailText = Asset.localizedString(forKey: "Snabble.Shoppingcart.notForThisPurchase")
                    }
                    return PaymentMethodItem(
                        title: paymentMethodDetail.displayName,
                        subtitle: detailText,
                        method: method,
                        methodDetail: paymentMethodDetail,
                        selectable: true,
                        active: hasCartMethods ? isCartMethod : false
                    )
                }
                return items
            } else {
                // Workaround: Bug Fix #APPS-995
                // https://snabble.atlassian.net/browse/APPS-995
                if method == .externalBilling && Snabble.shared.config.showExternalBilling == false {
                    return []
                }
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData"),
                    method: method,
                    methodDetail: nil,
                    selectable: true,
                    active: false
                )]
            }
            
        case .creditCardAmericanExpress, .creditCardVisa, .creditCardMastercard, .deDirectDebit, .giropayOneKlick, .twint, .postFinanceCard:
            if isPaymentMethodDetailAvailable {
                if hasCartMethods {
                    if isCartMethod {
                        let items = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodItem in
                            return PaymentMethodItem(
                                title: method.displayName,
                                subtitle: paymentMethodDetail.displayName,
                                method: method,
                                methodDetail: paymentMethodDetail,
                                selectable: true,
                                active: true
                            )
                        }
                        return items
                    } else {
                        return [PaymentMethodItem(
                            title: method.displayName,
                            subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.notForThisPurchase"),
                            method: method,
                            methodDetail: nil,
                            selectable: false,
                            active: false
                        )]
                    }
                } else {
                    let items = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodItem in
                        return PaymentMethodItem(
                            title: method.displayName,
                            subtitle: paymentMethodDetail.displayName,
                            method: method,
                            methodDetail: paymentMethodDetail,
                            selectable: true,
                            active: true
                        )
                    }
                    return items
                }
            } else {
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData"),
                    method: method,
                    methodDetail: nil,
                    selectable: true,
                    active: false
                )]
            }
        case .applePay:
            if !hasCartMethods || isCartMethod {
                let canMakePayments = ApplePay.canMakePayments(with: SnabbleCI.project.id)
                let subtitle = canMakePayments ? nil : Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData")
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: subtitle,
                    method: method,
                    methodDetail: nil,
                    selectable: true,
                    active: true
                )]
            } else {
                return [PaymentMethodItem(
                    title: method.displayName,
                    subtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.notForVendor"),
                    method: method,
                    methodDetail: nil,
                    selectable: false,
                    active: false
                )]
            }
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
            break
        }

        let item = PaymentMethodItem(
            title: method.displayName,
            subtitle: nil,
            method: method,
            methodDetail: nil,
            selectable: true,
            active: true
        )
        return [item]
    }
}

extension Project {
    public var orderedPaymentMethods: [RawPaymentMethod] {
        
        // and get them in the desired display order
        return RawPaymentMethod.orderedMethods
            .filter { paymentMethods.available.contains($0) }
    }
    
    public func paymentItems(for supportedMethods: [RawPaymentMethod]? = nil) -> [PaymentMethodItem] {
        var items = [PaymentMethodItem]()
        for method in orderedPaymentMethods {
            items.append(
                contentsOf: PaymentMethodItem.itemsFor(
                    method,
                    withPaymentMethodDetails: paymentMethodDetails,
                    andSupportedMethods: supportedMethods
                )
            )
        }
        return items
    }
}
