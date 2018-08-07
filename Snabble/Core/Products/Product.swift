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

    /// list of scannable codes (usually EANs/GTINs) for this product
    public let scannableCodes: Set<String>

    /// list of "EAN templates" for this product, if it's weight-dependent
    public let weighedItemIds: Set<String>?

    /// if not nil, refers to the SKU of the product that carries the price information for the deposit
    public let depositSku: String?

    /// if not nil, this is a "bundle product" and `bundledSku` refers to the product this is bundling
    /// (e.g. a case of beer will have this set, referring to the sku of the individual bottle)
    public let bundledSku: String?

    /// if true, this product represents a deposit and thus shouldn't be displayed in search results
    public let isDeposit: Bool

    /// if this product has an associated deposit, this is the deposit product's `price`
    internal(set) public var deposit: Int?

    /// if this product is contained in bundles (e.g. crates of bottles), this is the list of bundling products
    public let bundles: [Product]

    public let saleRestriction: SaleRestriction

    public let saleStop: Bool

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
        self.scannableCodes = try container.decode(.scannableCodes)
        self.weighedItemIds = try container.decodeIfPresent(.weighedItemIds)
        self.depositSku = try container.decodeIfPresent(.depositSku)
        self.bundledSku = try container.decodeIfPresent(.bundledSku)
        self.isDeposit = try container.decode(.isDeposit)
        self.saleRestriction = try container.decodeIfPresent(.saleRestriction) ?? .none
        self.saleStop = try container.decodeIfPresent(.saleStop) ?? false
        self.bundles = try container.decodeIfPresent(.bundles) ?? []
    }

    init(sku: String,
                name: String,
                description: String?,
                subtitle: String?,
                imageUrl: String?,
                basePrice: String?,
                listPrice: Int,
                discountedPrice: Int?,
                type: ProductType,
                scannableCodes: Set<String>,
                weighedItemIds: Set<String>?,
                depositSku: String?,
                bundledSku: String?,
                isDeposit: Bool,
                deposit: Int?,
                saleRestriction: SaleRestriction,
                saleStop: Bool,
                bundles: [Product]) {
        self.sku = sku
        self.name = name
        self.description = description
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.basePrice = basePrice
        self.listPrice = listPrice
        self.discountedPrice = discountedPrice
        self.type = type
        self.scannableCodes = scannableCodes
        self.weighedItemIds = weighedItemIds
        self.depositSku = depositSku
        self.bundledSku = bundledSku
        self.isDeposit = isDeposit
        self.deposit = deposit
        self.saleRestriction = saleRestriction
        self.saleStop = saleStop
        self.bundles = bundles
    }
}

/// price calculation stuff
extension Product {

    /// get the price for this product, multiplied by `quantityOrWeight`
    ///
    /// for single item products, `quantityOrWeight` is treated as the quantity
    /// for weighing products, `quantityOrWeight` is treated as the weight in grams
    ///
    /// - Parameters:
    ///   - quantityOrWeight: quantity or weight
    /// - Returns: the price
    public func priceFor(_ quantityOrWeight: Int) -> Int {
        switch self.type {
        case .singleItem:
            return quantityOrWeight * self.priceWithDeposit

        case .preWeighed, .userMustWeigh:
            let gramPrice = Decimal(self.price) / Decimal(1000.0)
            let total = Decimal(quantityOrWeight) * gramPrice

            return self.round(total)
        }
    }

    private func round(_ n: Decimal) -> Int {
        let mode = SnabbleAPI.project.roundingMode.mode
        let round = NSDecimalNumberHandler(roundingMode: mode,
                                           scale: 0,
                                           raiseOnExactness: false,
                                           raiseOnOverflow: false,
                                           raiseOnUnderflow: false,
                                           raiseOnDivideByZero: false)
        return (n as NSDecimalNumber).rounding(accordingToBehavior: round).intValue
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

/// price formatting
public enum Price {
    public static func format(_ price: Int) -> String {
        let divider = pow(10.0, SnabbleAPI.project.decimalDigits)
        let decimalPrice = Decimal(price) / divider
        return formatter.string(for: decimalPrice)!
    }

    private static var formatter: NumberFormatter {
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 1
        fmt.minimumFractionDigits = SnabbleAPI.project.decimalDigits
        fmt.maximumFractionDigits = SnabbleAPI.project.decimalDigits
        fmt.locale = Locale(identifier: SnabbleAPI.project.locale)
        fmt.currencyCode = SnabbleAPI.project.currency
        fmt.currencySymbol = SnabbleAPI.project.currencySymbol
        fmt.numberStyle = .currency
        return fmt
    }
}

/*
/// pretty names PoC

extension Product {

    var prettyName: String {
        var words = self.name.components(separatedBy: " ")
        for (index, word) in words.enumerated() {
            // COCA-COLA -> Coca-Cola
            var newWord = word.capitalized

            // 6X4 -> 6×4
            newWord = self.replace(newWord, "\\d+X\\d+", "X", "×")

            // 250MG -> 250mg
            for suffix in [ "L", "ML", "G", "MG", "GR", "KG", "CM" ] {
                newWord = self.replace(newWord, "\\d+\(suffix)$", suffix, suffix.lowercased())
            }

            // single-letter abbreviations and other stuff that needs to be all-lowercase
            for abbr in [ "U.", "M.", "O.", "In", "Aa", "Und", "Von", "Der", "Ca", "Ca." ] {
                if newWord == abbr {
                    newWord = abbr.lowercased()
                }
            }

            // some stuff needs to be all-uppercase
            for abbr in [ "Bh", "Ocb" ] {
                if newWord == abbr {
                    newWord = abbr.uppercased()
                }
            }

            words[index] = newWord
        }

        return words.joined(separator: " ")
    }

    private func replace(_ word: String, _ regex: String, _ string: String, _ replacement: String) -> String {
        let regex = try! NSRegularExpression(pattern: regex, options: [.caseInsensitive])
        let matches = regex.matches(in: word, options: [], range: NSMakeRange(0, word.count))
        if matches.count > 0 {
            return word.replacingOccurrences(of: string.capitalized, with: replacement)
        }
        return word
    }

}
*/
