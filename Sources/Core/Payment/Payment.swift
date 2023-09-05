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
            return PaymentSelection.paymentSelection(availableOfflineMethods.first)
        }

        // use Apple Pay, if possible
        if availableOnlineMethods.contains(.applePay) && ApplePay.canMakePayments(with: projectId) {
            return PaymentSelection.paymentSelection(.applePay, detail: nil)
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
            return PaymentSelection.paymentSelection(verified.rawPaymentMethod, detail: verified.paymentMethodDetail)
        }

        // prefer in-app payment methods like SEPA or CC
        for method in RawPaymentMethod.orderedMethods {
            guard let verified = verifyMethod(method) else {
                continue
            }
            return PaymentSelection.paymentSelection(verified.rawPaymentMethod, detail: verified.paymentMethodDetail)
        }

        return nil
    }
}

extension Project {
    public var payment: Payment {
        return Payment(for: id, methods: paymentMethods)
    }
}
