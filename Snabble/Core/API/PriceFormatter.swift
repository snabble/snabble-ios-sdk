//
//  PriceFormatter.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//
//  Price formatting stuff

import Foundation

public struct PriceFormatter {

    /// get the price for a product, multiplied by `quantityOrWeight`
    /// uses the project currently registered via `SnabbleUI.register()`
    ///
    /// for single item products, `quantityOrWeight` is treated as the quantity
    /// for weighing products, `quantityOrWeight` is treated as the weight in grams
    ///
    /// - Parameters:
    ///   - product: the product
    ///   - quantityOrWeight: quantity or weight
    /// - Returns: the price
    public static func priceFor(_ product: Product, _ quantityOrWeight: Int) -> Int {
        return self.priceFor(SnabbleUI.project, product, quantityOrWeight)
    }

    /// get the price for a product, multiplied by `quantityOrWeight`
    ///
    /// for single item products, `quantityOrWeight` is treated as the quantity
    /// for weighing products, `quantityOrWeight` is treated as the weight in grams
    ///
    /// - Parameters:
    ///   - project: the project
    ///   - product: the product
    ///   - quantityOrWeight: quantity or weight
    /// - Returns: the price
    public static func priceFor(_ project: Project, _ product: Product, _ quantityOrWeight: Int) -> Int {
        switch product.type {
        case .singleItem:
            return quantityOrWeight * product.priceWithDeposit

        case .preWeighed, .userMustWeigh:
            let gramPrice = Decimal(product.price) / Decimal(1000.0)
            let total = Decimal(quantityOrWeight) * gramPrice

            return self.round(total, project.roundingMode)
        }
    }

    private static func round(_ n: Decimal, _ roundingMode: RoundingMode) -> Int {
        let round = NSDecimalNumberHandler(roundingMode: roundingMode.mode,
                                           scale: 0,
                                           raiseOnExactness: false,
                                           raiseOnOverflow: false,
                                           raiseOnUnderflow: false,
                                           raiseOnDivideByZero: false)
        return (n as NSDecimalNumber).rounding(accordingToBehavior: round).intValue
    }

    /// Format a price
    /// uses the project currently registered via `SnabbleUI.register()`
    ///
    /// - Parameter price: the price to format
    /// - Returns: the formatted price
    public static func format(_ price: Int) -> String {
        return PriceFormatter.format(SnabbleUI.project, price)
    }

    /// Format a price
    ///
    /// - Parameter project: the project
    /// - Parameter price: the price to format
    /// - Returns: the formatted price
    public static func format(_ project: Project, _ price: Int) -> String {
        let divider = pow(10.0, project.decimalDigits)
        let decimalPrice = Decimal(price) / divider
        let fmt = self.formatter(project)
        return fmt.string(for: decimalPrice)!
    }

    private static func formatter(_ project: Project) -> NumberFormatter {
        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 1
        fmt.minimumFractionDigits = project.decimalDigits
        fmt.maximumFractionDigits = project.decimalDigits
        fmt.locale = Locale(identifier: project.locale)
        fmt.currencyCode = project.currency
        fmt.currencySymbol = project.currencySymbol
        fmt.numberStyle = .currency
        return fmt
    }
}

