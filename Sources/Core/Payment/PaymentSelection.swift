//
//  File.swift
//  
//
//  Created by Uwe Tilemann on 05.09.23.
//

import Foundation

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

extension PaymentSelection {
    public static func paymentSelection(_ method: RawPaymentMethod?, detail: PaymentMethodDetail? = nil) -> PaymentSelection? {
        if let method = method, let detail = detail {
            return PaymentSelection(method: method, detail: detail)
        } else if let detail = detail {
            return PaymentSelection(detail: detail)
        } else if let method = method {
            return PaymentSelection(method: method)
        } else {
            return nil
        }
    }
}
