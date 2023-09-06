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

    public init(method: RawPaymentMethod) {
        self.method = method
        self.detail = nil
    }

    public init(detail: PaymentMethodDetail) {
        self.method = detail.rawMethod
        self.detail = detail
    }
}
