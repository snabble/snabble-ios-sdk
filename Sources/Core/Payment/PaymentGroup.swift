//
//  PaymentGroup.swift
//  
//
//  Created by Uwe Tilemann on 06.09.23.
//

import Foundation

public protocol PaymentDefinition: Swift.Identifiable {
    var id: String { get }
    var value: PaymentSelection { get }
}

extension PaymentDefinition {
    public var id: String {
        value.method.rawValue
    }
    public var method: RawPaymentMethod {
        value.method
    }
    public var detail: PaymentMethodDetail? {
        value.detail
    }
}

public struct PaymentItem: PaymentDefinition {
    public var value: PaymentSelection
    
    public init(item: PaymentSelection) {
        self.value = item
    }
}

public struct PaymentGroup: PaymentDefinition {
    public let value: PaymentSelection
    public var items: [PaymentItem]

    public var id: String {
        return value.method.rawValue
    }
    
    public init(method: RawPaymentMethod, items: [PaymentItem]) {
        self.value = PaymentSelection(method: method)
        self.items = items
    }
}

public extension PaymentGroup {
     mutating func remove(at row: Int) {
        items.remove(at: row)
    }
}
