//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2023-09-07.
//

import Foundation

extension Project {
    public var paymentMethodDetails: [PaymentMethodDetail] {
        PaymentMethodDetails.userDetails(for: id)
    }

    public var preferredPayment: Payment? {
        let userDetails = self.paymentMethodDetails
        var availableOnlineMethods = paymentMethods.onlineAvailable

        guard !availableOnlineMethods.isEmpty else {
            guard let method = paymentMethods.offlineAvailable.first else {
                return nil
            }
            return Payment(method: method)
        }

        // use Apple Pay, if possible
        if availableOnlineMethods.contains(.applePay) && ApplePay.canMakePayments(with: id) {
            return Payment(method: .applePay)
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
                return Payment(method: verified.rawPaymentMethod)
            }
            return Payment(detail: detail)
        }

        // prefer in-app payment methods like SEPA or CC
        for method in RawPaymentMethod.orderedMethods {
            guard let verified = verifyMethod(method) else {
                continue
            }
            guard let detail = verified.paymentMethodDetail else {
                return Payment(method: verified.rawPaymentMethod)
            }
            return Payment(detail: detail)
        }

        return nil
    }
}

public extension Project {
    func availablePayments() -> [PaymentGroup] {
        var data: [PaymentGroup] = []

        if ApplePay.canMakePayments(with: id) {
            let group = PaymentGroup(method: .applePay, items: [Payment(method: .applePay)])
            data.append(group)
        }

        let details = PaymentMethodDetails.read().filter { detail in
            switch detail.methodData {
            case .teleCashCreditCard(let telecashData):
                return telecashData.projectId == id
            case .datatransCardAlias(let cardAlias):
                return cardAlias.projectId == id
            case .datatransAlias(let alias):
                return alias.projectId == id
            case .payoneCreditCard(let payoneData):
                return payoneData.projectId == id
            case .payoneSepa(let payoneSepaData):
                return payoneSepaData.projectId == id
            case .tegutEmployeeCard, .sepa, .paydirektAuthorization, .leinweberCustomerNumber, .invoiceByLogin:
                return Snabble.shared.project(for: id)?.paymentMethods.contains(where: { $0 == detail.rawMethod }) ?? false
            }
        }

        Dictionary(grouping: details, by: { $0.rawMethod })
            .values
            .sorted { $0[0].displayName < $1[0].displayName }
            .map { $0.map { Payment(detail: $0) } }
            .forEach { items in
                if let method = items.first?.method {
                    let group = PaymentGroup(method: method, items: items)
                    data.append(group)
                }
            }
        return data
    }
}
