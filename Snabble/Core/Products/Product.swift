//
//  Product.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

/// type of product: normal single items, pre-weighed by the seller, or to-be-weighed by the customer
public enum ProductType: Int, Codable {
    case singleItem
    case preWeighed
    case userMustWeigh
}

public enum SaleRestriction: Codable {
    case none
    case age(Int)
    case fsk

    enum CodingKeys: String, CodingKey {
        case age
        case fsk
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let age = try container.decodeIfPresent(Int.self, forKey: .age) {
            self = .age(age)
        } else if try container.decodeIfPresent(Bool.self, forKey: .fsk) == true {
            self = .fsk
        } else {
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .age(let age): try container.encode(age, forKey: .age)
        case .fsk: try container.encode(true, forKey: .fsk)
        case .none: break
        }
    }

    public init(_ code: Int64?) {
        guard let code = code else {
            self = .none
            return
        }

        let type = code & 0xFF
        switch type {
        case 1: // age
            let age = (code & 0xFF00) >> 8
            self = .age(Int(age))
        case 2: // fsk
            self = .fsk
        default:
            self = .none
        }
    }
}

extension SaleRestriction: Equatable {
    public static func==(_ lhs: SaleRestriction, _ rhs: SaleRestriction) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case (.age(let age1), .age(let age2)): return age1 == age2
        case (.fsk, .fsk): return true
        default: return false
        }
    }
}

public struct ScannableCode: Codable {
    public let code: String
    public let template: String
    public let transmissionCode: String?
    public let encodingUnit: Units?

    init(_ code: String, _ template: String, _ transmissionCode: String?, _ encodingUnit: Units?) {
        self.code = code
        self.template = template
        self.transmissionCode = transmissionCode
        self.encodingUnit = encodingUnit
    }
}

/// data for one product.
public struct Product: Codable {
    /// the stock keeping unit, unique identifier for this product
    public let sku: String

    /// the name of this product
    public let name: String

    /// optional description of the product
    public let description: String?

    /// optional subtitle of the product
    public let subtitle: String?

    /// optional image url for this product
    public let imageUrl: String?

    /// optional base price (e.g. "10 € / 100g") for this product
    public let basePrice: String?

    /// for single items: item price
    /// for weight-dependent products: price per kg
    public let listPrice: Int

    /// if not nil, this product has a (temporary) price different from its `listPrice`
    public let discountedPrice: Int?

    /// the product's type
    public let type: ProductType

    /// list of scannable codes for this product
    public let codes: [ScannableCode]

    /// if not nil, refers to the SKU of the product that carries the price information for the deposit
    public let depositSku: String?

    /// if not nil, this is a "bundle product" and `bundledSku` refers to the product this is bundling
    /// (e.g. a case of beer will have this set, referring to the sku of the individual bottle)
    public let bundledSku: String?

    /// if true, this product represents a deposit and thus shouldn't be displayed in search results
    public let isDeposit: Bool

    /// if this product has an associated deposit, this is the deposit product's `price`
    public let deposit: Int?

    /// if this product is contained in bundles (e.g. crates of bottles), this is the list of bundling products
    public let bundles: [Product]

    public let saleRestriction: SaleRestriction

    public let saleStop: Bool

    /// for products with unit-dependent prices.
    /// `referenceUnit` specifies the Unit that the product's list price refers to, e.g. `.kilogram`.
    public let referenceUnit: Units?

    /// for products with unit-dependent prices.
    /// `encodingUnit` specifies the Unit that the this product's scanned code refers to, e.g. `.gram`.
    public let encodingUnit: Units?

    /// convenience accessor for the price
    public var price: Int {
        return self.discountedPrice ?? self.listPrice
    }

    /// convenience accessor for price including deposit
    public var priceWithDeposit: Int {
        return self.price + (self.deposit ?? 0)
    }

    /// convenience method: is the price weight-dependent?
    public var weightDependent: Bool {
        return self.type != .singleItem
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.sku = try container.decode(.sku)
        self.name = try container.decode(.name)
        self.description = try container.decodeIfPresent(.description)
        self.subtitle = try container.decodeIfPresent(.subtitle)
        self.imageUrl = try container.decodeIfPresent(.imageUrl)
        self.basePrice = try container.decodeIfPresent(.basePrice)
        self.listPrice = try container.decode(.listPrice)
        self.discountedPrice = try container.decodeIfPresent(.discountedPrice)
        self.type = try container.decode(.type)
        self.codes = try container.decode(.codes)
        self.depositSku = try container.decodeIfPresent(.depositSku)
        self.bundledSku = try container.decodeIfPresent(.bundledSku)
        self.isDeposit = try container.decode(.isDeposit)
        self.deposit = try container.decodeIfPresent(.deposit)
        self.saleRestriction = try container.decodeIfPresent(.saleRestriction) ?? .none
        self.saleStop = try container.decodeIfPresent(.saleStop) ?? false
        self.bundles = try container.decodeIfPresent(.bundles) ?? []
        self.referenceUnit = try container.decodeIfPresent(.referenceUnit)
        self.encodingUnit = try container.decodeIfPresent(.encodingUnit)
    }

    init(sku: String,
         name: String,
         description: String? = nil,
         subtitle: String? = nil,
         imageUrl: String? = nil,
         basePrice: String? = nil,
         listPrice: Int,
         discountedPrice: Int? = nil,
         type: ProductType,
         codes: [ScannableCode] = [],
         depositSku: String? = nil,
         bundledSku: String? = nil,
         isDeposit: Bool = false,
         deposit: Int? = nil,
         saleRestriction: SaleRestriction = .none,
         saleStop: Bool = false,
         bundles: [Product] = [],
         referenceUnit: Units? = nil,
         encodingUnit: Units? = nil) {
        self.sku = sku
        self.name = name
        self.description = description
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.basePrice = basePrice
        self.listPrice = listPrice
        self.discountedPrice = discountedPrice
        self.type = type
        self.codes = codes
        self.depositSku = depositSku
        self.bundledSku = bundledSku
        self.isDeposit = isDeposit
        self.deposit = deposit
        self.saleRestriction = saleRestriction
        self.saleStop = saleStop
        self.bundles = bundles
        self.referenceUnit = referenceUnit
        self.encodingUnit = encodingUnit
    }
}

/// conform to Hashable
extension Product: Hashable {
    public static func ==(_ lhs: Product, _ rhs: Product) -> Bool {
        return lhs.sku == rhs.sku
    }

    public var hashValue: Int {
        return self.sku.hashValue
    }
}
