//
//  PaymentModel.swift
//  
//
//  Created by Uwe Tilemann on 04.09.23.
//

import Foundation

public struct PaymentSelection {
    let method: RawPaymentMethod
    let detail: PaymentMethodDetail?
}

public struct PaymentModel {
    public let methods: [RawPaymentMethod]
    public var userDetails: [PaymentMethodDetail] = []
    public var preferedPayment: PaymentSelection?

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

public extension PaymentModel {
    static func userDetails(for projectId: Identifier<Project>?) -> [PaymentMethodDetail] {
        return PaymentMethodDetails.read()
           .filter { $0.rawMethod.isAvailable }
           .filter { $0.projectId != nil ? $0.projectId == projectId : true }
    }
}

public extension Project {
    var paymentModel: PaymentModel {
        var model = PaymentModel(methods: paymentMethods)
        model.userDetails = PaymentModel.userDetails(for: id)
        
        return model
    }
}
