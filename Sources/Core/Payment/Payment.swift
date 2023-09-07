//
//  Payment.swift
//  
//
//  Created by Uwe Tilemann on 04.09.23.
//

import Foundation

public struct Payment {
    public let method: RawPaymentMethod
    public let detail: PaymentMethodDetail?

    public init(method: RawPaymentMethod) {
        self.method = method
        self.detail = nil
    }

    public init(detail: PaymentMethodDetail) {
        self.method = detail.rawMethod
        self.detail = detail
    }
}

extension Payment: Swift.Identifiable {
    public var id: String {
        guard let detail = detail else {
            return method.rawValue
        }
        return detail.id.uuidString
    }
}

public extension PaymentMethodDetails {
    static func userDetails(for projectId: Identifier<Project>?) -> [PaymentMethodDetail] {
        return PaymentMethodDetails.read()
           .filter { $0.rawMethod.isAvailable }
           .filter { $0.projectId != nil ? $0.projectId == projectId : true }
    }
}

extension Array where Element == RawPaymentMethod {
    public var available: Self {
        filter { $0.isAvailable }
    }

    public var offlineAvailable: Self {
        available.filter { $0.offline }
    }

    public var onlineAvailable: Self {
        available.filter { !$0.offline }
    }
}
