//
//  PriceFormatter.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//
//  Price formatting stuff

import Foundation

public struct PriceFormatter: Sendable {
    private let decimalDigits: Int
    private let formatter: NumberFormatter

    public init(_ project: Project) {
        self.init(project.decimalDigits, project.locale, project.currency, project.currencySymbol)
    }

    public init(_ decimalDigits: Int, _ locale: String, _ currency: String, _ currencySymbol: String) {
        self.decimalDigits = decimalDigits

        let fmt = NumberFormatter()
        fmt.minimumIntegerDigits = 1
        fmt.minimumFractionDigits = decimalDigits
        fmt.maximumFractionDigits = decimalDigits
        fmt.locale = Locale(identifier: locale)
        fmt.currencyCode = currency
        fmt.currencySymbol = currencySymbol
        fmt.numberStyle = .currency

        self.formatter = fmt
    }

    public func format(_ price: Int) -> String {
        let divider = pow(10.0, self.decimalDigits)
        let decimalPrice = Decimal(price) / divider
        return self.formatter.string(for: decimalPrice)!
    }
}
