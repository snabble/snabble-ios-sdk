//
//  PaymentGroup.swift
//  
//
//  Created by Uwe Tilemann on 06.09.23.
//

import Foundation

public protocol PaymentItem: Swift.Identifiable {
    var id: String { get }
    var value: PaymentSelection { get }
}

public struct PaymentGroup: PaymentItem {
    public var value: PaymentSelection
    public let items: [any PaymentItem]

    public var id: String {
        return value.method.rawValue
    }
    
    init(method: RawPaymentMethod, items: [any PaymentItem]) {
        self.value = PaymentSelection(method: method)
        self.items = items
    }
}
