//
//  PaymentGroup.swift
//  
//
//  Created by Uwe Tilemann on 06.09.23.
//

import Foundation

public struct PaymentGroup: Swift.Identifiable {
    public let rawPaymentMethod: RawPaymentMethod
    public var items: [Payment]

    public var id: String {
        return rawPaymentMethod.rawValue
    }
    
    public init(method: RawPaymentMethod, items: [Payment]) {
        self.rawPaymentMethod = method
        self.items = items
    }
}

public extension PaymentGroup {
     mutating func remove(at row: Int) {
        items.remove(at: row)
    }
}
