//
//  Units.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

public enum Quantity: String {
    case volume
    case capacity
    case area
    case distance
    case mass
    case count
    case amount
}

/// units for variable-price products
public enum Unit: String, Codable {
    // length
    case millimeter = "mm"
    case centimeter = "cm"
    case meter = "m"

    // fluids
    case milliliter = "ml"
    case deciliter = "dl"
    case liter = "l"

    // areas
    case squareCentimeter = "cm2"
    case squareMeter = "m2"

    // volumes
    case cubicCentimeter = "cm3"
    case cubicMeter = "m3"

    // weight
    case gram = "g"
    case kilogram = "kg"
    case tonne = "t"

    // others
    case piece
    case price

    var quantity: Quantity {
        switch self {
        case .millimeter, .centimeter, .meter: return .distance
        case .milliliter, .deciliter, .liter: return .volume
        case .squareCentimeter, .squareMeter: return .area
        case .cubicCentimeter, .cubicMeter: return .capacity
        case .gram, .kilogram, .tonne: return .mass
        case .piece: return .count
        case .price: return .amount
        }
    }

    static func from(_ rawValue: String?) -> Unit? {
        guard let rawValue = rawValue else {
            return nil
        }
        return Unit(rawValue: rawValue)
    }

    var hasUnit: Bool {
        switch self {
        case .piece, .price:
            return false
        default:
            return true
        }
    }
}

extension Unit {
    var display: String {
        switch self {
        case .squareMeter: return "m²"
        case .squareCentimeter: return "cm²"
        case .cubicMeter: return "m³"
        case .cubicCentimeter: return "cm³"
        case .piece: return ""
        case .price: return ""
        default: return self.rawValue
        }
    }
}

extension Unit {

    ///
    /// Convert a value in a given unit into another unit within the same quantity
    ///
    /// - Parameters:
    ///   - value: the value to convert
    ///   - from: the unit of `value`
    ///   - to: the desired result unit
    /// - Returns: the converted value, or 0 if the conversion is impossible
    public static func convert(_ value: Int, from: Unit, to: Unit) -> Decimal {
        return Unit.convert(Decimal(value), from: from, to: to)
    }

    ///
    /// Convert a value in a given unit into another unit within the same quantity
    ///
    /// - Parameters:
    ///   - value: the value to convert
    ///   - from: the unit of `value`
    ///   - to: the desired result unit
    /// - Returns: the converted value, or 0 if the conversion is impossible
    public static func convert(_ value: Decimal, from: Unit, to: Unit) -> Decimal {
        if from == to {
            return value
        }

        guard
            let candidates = conversions[from.quantity],
            let conversion = candidates.filter({ $0.from == from && $0.to == to }).first
        else {
            return 0
        }

        return value * conversion.factor / conversion.divisor
    }

    private struct Conversion {
        let from: Unit
        let to: Unit
        let factor: Decimal
        let divisor: Decimal
    }

    private static let conversions = Unit.initializeConversions()

    private typealias Conversions = [ Quantity: [Conversion] ]

    private static func initializeConversions() -> Conversions {
        var conversions = Conversions()

        self.addConversion(from: .liter, to: .deciliter, 10, 1, &conversions)
        self.addConversion(from: .liter, to: .milliliter, 1000, 1, &conversions)
        self.addConversion(from: .deciliter, to: .milliliter, 100, 1, &conversions)

        self.addConversion(from: .cubicMeter, to: .cubicCentimeter, 1_000_000, 1, &conversions)

        self.addConversion(from: .squareMeter, to: .squareCentimeter, 10_000, 1, &conversions)

        self.addConversion(from: .meter, to: .centimeter, 100, 1, &conversions)
        self.addConversion(from: .meter, to: .millimeter, 1000, 1, &conversions)
        self.addConversion(from: .centimeter, to: .millimeter, 10, 1, &conversions)

        self.addConversion(from: .tonne, to: .kilogram, 1000, 1, &conversions)
        self.addConversion(from: .tonne, to: .gram, 1_000_000, 1, &conversions)
        self.addConversion(from: .kilogram, to: .gram, 1000, 1, &conversions)

        return conversions
    }

    private static func addConversion(from: Unit, to: Unit, _ factor: Decimal, _ divisor: Decimal, _ conversions: inout Conversions ) {
        let fromTo = Conversion(from: from, to: to, factor: factor, divisor: divisor)
        let toFrom = Conversion(from: to, to: from, factor: divisor, divisor: factor)
        conversions[from.quantity, default: []].append(contentsOf: [fromTo, toFrom])
    }
}


