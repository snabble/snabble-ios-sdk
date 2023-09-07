//
//  PaymentGroup.swift
//  
//
//  Created by Uwe Tilemann on 06.09.23.
//

import Foundation

public struct PaymentGroup: Swift.Identifiable {
    public let value: Payment
    public var items: [Payment]

    public var id: String {
        return value.method.rawValue
    }
    
    public init(method: RawPaymentMethod, items: [Payment]) {
        self.value = Payment(method: method)
        self.items = items
    }
}

public extension PaymentGroup {
     mutating func remove(at row: Int) {
        items.remove(at: row)
    }
}
