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

    /// if true, this product represents a deposit and thus shouldn't be displayed in search results
    public let isDeposit: Bool

    /// if this product has an associated deposit, this is the deposit product's `price`
    internal(set) public var deposit: Int?

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
    ///   - roundingMode: the rounding mode to use, default is `.up`
    /// - Returns: the price
    public func priceFor(_ quantityOrWeight: Int, _ roundingMode: NSDecimalNumber.RoundingMode = .up) -> Int {
        switch self.type {
        case .singleItem:
            return quantityOrWeight * self.priceWithDeposit

        case .preWeighed, .userMustWeigh:
            let gramPrice = Decimal(self.price) / Decimal(1000.0)
            let total = Decimal(quantityOrWeight) * gramPrice

            return self.round(total, roundingMode)
        }
    }

    private func round(_ n: Decimal, _ roundingMode: NSDecimalNumber.RoundingMode) -> Int {
        let round = NSDecimalNumberHandler(roundingMode: roundingMode, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
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

// price formatting
public struct Price {

    public static func format(_ price: Int) -> String {
        return format(price, decimalDigits: APIConfig.shared.project.decimalDigits, currency: APIConfig.shared.project.currencySymbol)
    }

    public static func format(_ price: Int, decimalDigits: Int, currency: String) -> String {
        let decimalPrice = decimal(price, decimalDigits)
        return formatter.string(for: decimalPrice)!
    }

    private static func decimal(_ price: Int, _ decimalDigits: Int) -> Decimal {
        let divider = pow(10.0, decimalDigits)
        return Decimal(price) / divider
    }

    private static var formatter: NumberFormatter {
        let fmt = NumberFormatter()
        fmt.minimumFractionDigits = APIConfig.shared.project.decimalDigits
        fmt.maximumFractionDigits = APIConfig.shared.project.decimalDigits
        fmt.minimumIntegerDigits = 1
        fmt.numberStyle = .currency
        fmt.currencySymbol = APIConfig.shared.project.currencySymbol
        return fmt
    }

}

