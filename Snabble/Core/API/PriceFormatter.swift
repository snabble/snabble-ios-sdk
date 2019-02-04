//
//  PriceFormatter.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//
//  Price formatting stuff

import Foundation

public struct PriceFormatter {

    /// get the price for a product, multiplied by `quantityOrWeight`
    ///
    /// for single item products, `quantityOrWeight` is treated as the quantity
    /// for weighing products, `quantityOrWeight` is treated as the unit in `encodingUnits`
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
            // if we get here but have no units, fall back to our previous default of kilograms/grams
            let referenceUnit = product.referenceUnit ?? .kilogram
            let encodingUnit = product.encodingUnit ?? .gram

            let unitPrice = Units.convert(product.price, from: encodingUnit, to: referenceUnit)
            let total = Decimal(quantityOrWeight) * unitPrice

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

