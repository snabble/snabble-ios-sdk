//
//  PriceFormatter+UI.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//
//  Price formatting stuff

import Foundation

extension PriceFormatter {

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
    public static func priceFor(_ product: Product, _ quantityOrWeight: Int, _ encodingUnit: Units? = nil, _ referencePrice: Int? = nil) -> Int {
        return self.priceFor(SnabbleUI.project, product, quantityOrWeight, encodingUnit, referencePrice)
    }

    /// Format a price
    /// uses the project currently registered via `SnabbleUI.register()`
    ///
    /// - Parameter price: the price to format
    /// - Returns: the formatted price
    public static func format(_ price: Int) -> String {
        return PriceFormatter.format(SnabbleUI.project, price)
    }


}

