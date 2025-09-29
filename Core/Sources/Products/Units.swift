//
//  Units.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

public enum Dimension {
    case volume
    case capacity
    case area
    case distance
    case mass
    case count
    case amount
}

/// units for variable-price products
public enum Units: String, Codable, Equatable, Sendable {
    // length
    case meter = "m"            // 1
    case decimeter = "dm"       // 10
    case centimeter = "cm"      // 100
    case millimeter = "mm"      // 1000

    // fluids
    case liter = "l"            // 1
    case deciliter = "dl"       // 10
    case centiliter = "cl"      // 100
    case milliliter = "ml"      // 1000

    // areas
    case squareMeter = "m2"             // 1
    case squareMeterTenth = "m2e-1"     // 10
    case squareDecimeter = "dm2"        // 100
    case squareDecimeterTenth = "m2e-3" // 1000
    case squareCentimeter = "cm2"       // 10000

    // volumes
    case cubicMeter = "m3"          // 1
    case cubicCentimeter = "cm3"    // 1_000_000

    // mass
    case tonne = "t"            // 0.001
    case kilogram = "kg"        // 1
    case decagram = "dag"       // 10
    case hectogram = "hg"       // 100
    case gram = "g"             // 1000

    // others
    case piece
    case price

    var quantity: Dimension {
        switch self {
        case .millimeter, .centimeter, .decimeter, .meter: return .distance
        case .milliliter, .centiliter, .deciliter, .liter: return .volume
        case .squareCentimeter, .squareDecimeterTenth, .squareDecimeter, .squareMeterTenth, .squareMeter: return .area
        case .cubicCentimeter, .cubicMeter: return .capacity
        case .gram, .decagram, .hectogram, .kilogram, .tonne: return .mass
        case .piece: return .count
        case .price: return .amount
        }
    }

    static func from(_ rawValue: String?) -> Units? {
        guard let rawValue = rawValue else {
            return nil
        }
        return Units(rawValue: rawValue)
    }

    public var hasDimension: Bool {
        switch self {
        case .piece, .price:
            return false
        default:
            return true
        }
    }

    public func fractionalUnit(_ div: Int) -> Units? {
        return self.fractionalUnit(Decimal(div))
    }

    public func fractionalUnit(_ div: Decimal) -> Units? {
        guard let conv = Units.conversions[self.quantity] else {
            return nil
        }

        let unit = conv.first { $0.from == self && $0.factor == div}
        return unit?.to
    }

}

extension Units {
    public var display: String {
        switch self {
        case .squareMeter: return "m²"
        case .squareCentimeter: return "cm²"
        case .cubicMeter: return "m³"
        case .cubicCentimeter: return "cm³"
        case .piece: return ""
        case .price: return ""
        case .hectogram: return "100g"
        case .decagram: return "10g"
        case .centiliter: return "100ml"
        case .deciliter: return "10ml"
        default: return self.rawValue
        }
    }
}

extension Units {
    ///
    /// Convert a value in a given unit into another unit within the same quantity
    ///
    /// - Parameters:
    ///   - value: the value to convert
    ///   - from: the unit of `value`
    ///   - to: the desired result unit
    /// - Returns: the converted value, or 0 if the conversion is impossible
    public static func convert(_ value: Int, from: Units, to: Units) -> Decimal {
        return Units.convert(Decimal(value), from: from, to: to)
    }

    ///
    /// Convert a value in a given unit into another unit within the same quantity
    ///
    /// - Parameters:
    ///   - value: the value to convert
    ///   - from: the unit of `value`
    ///   - to: the desired result unit
    /// - Returns: the converted value, or 0 if the conversion is impossible
    public static func convert(_ value: Decimal, from: Units, to: Units) -> Decimal {
        if from == to {
            return value
        }

        guard
            let candidates = conversions[from.quantity],
            let conversion = candidates.filter({ $0.from == from && $0.to == to }).first
        else {
            Log.warn("cannot convert units from \(from) to \(to)")
            return 0
        }

        return value * conversion.factor / conversion.divisor
    }

    private struct Conversion {
        let from: Units
        let to: Units
        let factor: Decimal
        let divisor: Decimal
    }

    nonisolated(unsafe) private static let conversions = Units.initializeConversions()

    private typealias Conversions = [ Dimension: [Conversion] ]

    private static func initializeConversions() -> Conversions {
        var conversions = Conversions()

        self.addConversion(from: .liter, to: .milliliter, 1000, 1, &conversions)
        self.addConversion(from: .liter, to: .centiliter, 100, 1, &conversions)
        self.addConversion(from: .liter, to: .deciliter, 10, 1, &conversions)
        self.addConversion(from: .deciliter, to: .milliliter, 100, 1, &conversions)
        self.addConversion(from: .deciliter, to: .centiliter, 10, 1, &conversions)
        self.addConversion(from: .centiliter, to: .milliliter, 10, 1, &conversions)

        self.addConversion(from: .cubicMeter, to: .cubicCentimeter, 1_000_000, 1, &conversions)

        self.addConversion(from: .squareMeter, to: .squareCentimeter, 10_000, 1, &conversions)
        self.addConversion(from: .squareMeter, to: .squareDecimeterTenth, 1000, 1, &conversions)
        self.addConversion(from: .squareMeter, to: .squareDecimeter, 100, 1, &conversions)
        self.addConversion(from: .squareMeter, to: .squareMeterTenth, 10, 1, &conversions)

        self.addConversion(from: .meter, to: .millimeter, 1000, 1, &conversions)
        self.addConversion(from: .meter, to: .centimeter, 100, 1, &conversions)
        self.addConversion(from: .meter, to: .decimeter, 10, 1, &conversions)
        self.addConversion(from: .decimeter, to: .millimeter, 100, 1, &conversions)
        self.addConversion(from: .decimeter, to: .centimeter, 10, 1, &conversions)
        self.addConversion(from: .centimeter, to: .millimeter, 10, 1, &conversions)

        self.addConversion(from: .tonne, to: .kilogram, 1000, 1, &conversions)
        self.addConversion(from: .tonne, to: .gram, 1_000_000, 1, &conversions)

        self.addConversion(from: .kilogram, to: .gram, 1000, 1, &conversions)
        self.addConversion(from: .kilogram, to: .decagram, 100, 1, &conversions)
        self.addConversion(from: .kilogram, to: .hectogram, 10, 1, &conversions)
        self.addConversion(from: .hectogram, to: .gram, 100, 1, &conversions)
        self.addConversion(from: .hectogram, to: .decagram, 10, 1, &conversions)
        self.addConversion(from: .decagram, to: .gram, 10, 1, &conversions)

        return conversions
    }

    private static func addConversion(from: Units, to: Units, _ factor: Decimal, _ divisor: Decimal, _ conversions: inout Conversions ) {
        let fromTo = Conversion(from: from, to: to, factor: factor, divisor: divisor)
        let toFrom = Conversion(from: to, to: from, factor: divisor, divisor: factor)
        conversions[from.quantity, default: []].append(contentsOf: [fromTo, toFrom])
    }
}
