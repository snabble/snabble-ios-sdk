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

public struct PaymentSelection {
    public let method: RawPaymentMethod
    public let detail: PaymentMethodDetail?
    
    public init(method: RawPaymentMethod, detail: PaymentMethodDetail? = nil) {
        self.method = method
        self.detail = detail
    }
    public init(detail: PaymentMethodDetail) {
        self.method = detail.rawMethod
        self.detail = detail
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
        guard let detail = userDetails.first else {
            return nil
        }
        return PaymentSelection(detail: detail)
    }
}

extension Project {
    public var payment: Payment {
        return Payment(for: id, methods: paymentMethods)
    }
}

