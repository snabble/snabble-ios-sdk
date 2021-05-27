//
//  ShoppingListItem.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public enum ShoppingListEntry {
    case product(Product)
    case custom(String)
}

public final class ShoppingListItem: Codable {
    public var quantity = 0
    public var checked = false
    public let entry: ShoppingListEntry

    public var product: Product? {
        switch entry {
        case .product(let product): return product
        default: return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case quantity, checked, text, product, type
    }

    public init(product: Product) {
        self.entry = .product(product)
    }

    public init(text: String) {
        self.entry = .custom(text)
        self.quantity = 1
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.checked = try container.decode(Bool.self, forKey: .checked)

        if let product = try container.decodeIfPresent(Product.self, forKey: .product) {
            self.entry = .product(product)
        } else if let text = try container.decodeIfPresent(String.self, forKey: .text) {
            self.entry = .custom(text)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .product, in: container, debugDescription: "No product or text")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.quantity, forKey: .quantity)
        try container.encode(self.checked, forKey: .checked)

        switch entry {
        case .custom(let text): try container.encode(text, forKey: .text)
        case .product(let product): try container.encode(product, forKey: .product)
        }
    }
}
