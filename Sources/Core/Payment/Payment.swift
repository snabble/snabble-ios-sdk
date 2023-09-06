//
//  Payment.swift
//  
//
//  Created by Uwe Tilemann on 04.09.23.
//

import Foundation

public extension PaymentMethodDetails {
    static func userDetails(for projectId: Identifier<Project>?) -> [PaymentMethodDetail] {
        return PaymentMethodDetails.read()
           .filter { $0.rawMethod.isAvailable }
           .filter { $0.projectId != nil ? $0.projectId == projectId : true }
    }
}

public struct Payment {
    public let projectId: Identifier<Project>
    public let methods: [RawPaymentMethod]
    
    public init(for projectId: Identifier<Project>, methods: [RawPaymentMethod]) {
        self.projectId = projectId
        self.methods = methods
    }
}

extension Payment {
    public var availableMethods: [RawPaymentMethod] {
        methods.filter { $0.isAvailable }
    }
    public var availableOfflineMethods: [RawPaymentMethod] {
        availableMethods.filter { $0.offline }
    }
    public var availableOnlineMethods: [RawPaymentMethod] {
        availableMethods.filter { !$0.offline }
    }
}

extension Payment {
    public var userDetails: [PaymentMethodDetail] {
        return PaymentMethodDetails.userDetails(for: projectId)
    }
    
    public var preferredPayment: PaymentSelection? {
        
        let userDetails = userDetails
        var availableOnlineMethods = self.availableOnlineMethods

        guard !availableOnlineMethods.isEmpty else {
            guard let method = availableOfflineMethods.first else {
                return nil
            }
            return PaymentSelection(method: method)
        }

        // use Apple Pay, if possible
        if availableOnlineMethods.contains(.applePay) && ApplePay.canMakePayments(with: projectId) {
            return PaymentSelection(method: .applePay)
        } else {
            availableOnlineMethods.removeAll { $0 == .applePay }
        }

        let verifyMethod: (RawPaymentMethod) -> (rawPaymentMethod: RawPaymentMethod, paymentMethodDetail: PaymentMethodDetail?)? = { method in
            guard availableOnlineMethods.contains(method) else {
                return nil
            }

            guard method.dataRequired else {
                return (method, nil)
            }

            guard let userMethod = userDetails.first(where: { $0.rawMethod == method }) else {
                return nil
            }
            return (userMethod.rawMethod, userMethod)
        }

        // prefer in-app payment methods like SEPA or CC
        for method in RawPaymentMethod.preferredOnlineMethods {
            guard let verified = verifyMethod(method) else {
                continue
            }
            guard let detail = verified.paymentMethodDetail else {
                return PaymentSelection(method: verified.rawPaymentMethod)
            }
            return PaymentSelection(detail: detail)
        }

        // prefer in-app payment methods like SEPA or CC
        for method in RawPaymentMethod.orderedMethods {
            guard let verified = verifyMethod(method) else {
                continue
            }
            guard let detail = verified.paymentMethodDetail else {
                return PaymentSelection(method: verified.rawPaymentMethod)
            }
            return PaymentSelection(detail: detail)
        }

        return nil
    }
}

public extension Payment {
    func availablePayments() -> [PaymentGroup] {
        var data: [PaymentGroup] = []
        
        if ApplePay.canMakePayments(with: projectId) {
            let group = PaymentGroup(method: .applePay, items: [PaymentItem(item: PaymentSelection(method: .applePay))])
            data.append(group)
        }
        
        let details = PaymentMethodDetails.read().filter { detail in
            switch detail.methodData {
            case .teleCashCreditCard(let telecashData):
                return telecashData.projectId == projectId
            case .datatransCardAlias(let cardAlias):
                return cardAlias.projectId == projectId
            case .datatransAlias(let alias):
                return alias.projectId == projectId
            case .payoneCreditCard(let payoneData):
                return payoneData.projectId == projectId
            case .payoneSepa(let payoneSepaData):
                return payoneSepaData.projectId == projectId
            case .tegutEmployeeCard, .sepa, .paydirektAuthorization, .leinweberCustomerNumber, .invoiceByLogin:
                return Snabble.shared.project(for: projectId)?.paymentMethods.contains(where: { $0 == detail.rawMethod }) ?? false
            }
        }
        
        Dictionary(grouping: details, by: { $0.rawMethod })
            .values
            .sorted { $0[0].displayName < $1[0].displayName }
            .map { $0.map { PaymentItem(item: PaymentSelection(detail: $0)) } }
            .forEach { items in
                if let method = items.first?.value.method {
                    let group = PaymentGroup(method: method, items: items)
                    data.append(group)
                }
            }
        return data
    }
}

extension Project {
    public var payment: Payment {
        return Payment(for: id, methods: paymentMethods)
    }
}
