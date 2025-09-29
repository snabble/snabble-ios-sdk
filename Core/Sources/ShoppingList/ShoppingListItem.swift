//
//  ShoppingListItem.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct ProductListEntry: Codable {
    public let sku: String
    public let name: String
    public let imageUrl: String?
    public let order: Int

    public init(sku: String, name: String, imageUrl: String?, order: Int) {
        self.sku = sku
        self.name = name
        self.imageUrl = imageUrl
        self.order = order
    }

    public init(_ product: Product) {
        self.init(sku: product.sku, name: product.name, imageUrl: product.imageUrl, order: 0)
    }
}

public struct TagEntry: Codable {
    public let name: String
    public let order: Int
    public let categories: Set<String>

    public init(name: String, order: Int, categories: Set<String>) {
        self.name = name
        self.order = order
        self.categories = categories
    }
}

public enum ShoppingListEntry {
    case product(ProductListEntry)
    case tag(TagEntry)
    case custom(String)
}

public final class ShoppingListItem: Codable, @unchecked Sendable {
    public var quantity = 0
    public var checked = false
    public let entry: ShoppingListEntry

    public var product: ProductListEntry? {
        switch entry {
        case .product(let product): return product
        default: return nil
        }
    }

    public var name: String {
        switch entry {
        case .product(let product): return product.name
        case .tag(let tag): return tag.name
        case .custom(let text): return text
        }
    }

    enum CodingKeys: String, CodingKey {
        case quantity, checked
        case product, tag, custom
    }

    public convenience init(product: Product) {
        self.init(product: ProductListEntry(product))
    }

    public init(product: ProductListEntry) {
        self.entry = .product(product)
    }

    public init(tag: TagEntry) {
        self.entry = .tag(tag)
    }

    public init(text: String) {
        self.entry = .custom(text)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.checked = try container.decode(Bool.self, forKey: .checked)

        if let product = try container.decodeIfPresent(ProductListEntry.self, forKey: .product) {
            self.entry = .product(product)
        } else if let custom = try container.decodeIfPresent(String.self, forKey: .custom) {
            self.entry = .custom(custom)
        } else if let tag = try container.decodeIfPresent(TagEntry.self, forKey: .tag) {
            self.entry = .tag(tag)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .product, in: container, debugDescription: "No product or text")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.quantity, forKey: .quantity)
        try container.encode(self.checked, forKey: .checked)

        switch entry {
        case .product(let product): try container.encode(product, forKey: .product)
        case .tag(let tag): try container.encode(tag, forKey: .tag)
        case .custom(let text): try container.encode(text, forKey: .custom)
        }
    }
}

extension ShoppingListItem: Equatable {
    public static func == (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        switch (lhs.entry, rhs.entry) {
        case (.product(let product1), .product(let product2)):
            return product1.sku == product2.sku
        case (.tag(let tag1), .tag(let tag2)):
            return tag1.name == tag2.name
        case (.custom(let text1), .custom(let text2)):
            return text1 == text2
        default:
            return false
        }
    }
}

extension ShoppingListItem: Comparable {
    // sorting rules:
    //   tags and products come first, sorted by their `order`, then name
    //   text entries are last, sorted by name
    public static func < (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        // swiftlint:disable identifier_name
        switch (lhs.entry, rhs.entry) {
        case (.tag(let t1), .tag(let t2)):
            return t1.order == t2.order ? t1.name < t2.name : t1.order < t2.order
        case (.tag(let t), .product(let p)):
            return t.order == p.order ? t.name < p.name : t.order < p.order
        case (.product(let p), .tag(let t)):
            return p.order == t.order ? p.name < t.name : p.order < t.order
        case (.product(let p1), .product(let p2)):
            return p1.order == p2.order ? p1.name < p2.name : p1.order < p2.order
        case (.product, .custom): return true
        case (.custom, .product): return false
        case (.tag, .custom): return true
        case (.custom, .tag): return false

        case (.custom(let c1), .custom(let c2)): return c1 < c2
        }
        // swiftlint:enable identifier_name
    }
}
