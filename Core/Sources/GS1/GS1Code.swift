//
//  GS1Code.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// a parsed Application Identifier with it value(s)
public struct GS1CodeElement: Sendable {
    public let definition: ApplicationIdentifier
    public let values: [String]

    private static let decimalPrefixes = Set(["31", "32", "33", "34", "35", "36", "39"])

    public var decimal: Decimal? {
        let pfx = String(definition.prefix.prefix(2))
        guard
            Self.decimalPrefixes.contains(pfx),
            let commaPosition = definition.prefix.last?.asciiValue,
            let value = values.last,
            let decimal = Decimal(string: value)
        else {
            return nil
        }

        let divisor = pow(Decimal(10), Int(commaPosition - 48))
        return decimal / divisor
    }
}

/// parse a GS1 barcode into its constituent application identifiers
///
/// any skipped/unknown/invalid code parts will be returned in `skipped`
public struct GS1Code: Sendable {
    public static let gs = "\u{1d}"

    nonisolated(unsafe) private static var prefixMap: [String: [ApplicationIdentifier]] = {
        var map = [String: [ApplicationIdentifier]]()
        for ai in ApplicationIdentifier.allIdentifiers {
            let pfx = String(ai.prefix.prefix(2))
            map[pfx, default: []].append(ai)
        }

        #if DEBUG
        for (key, values) in map {
            let len = values[0].prefix.count
            values.forEach {
                assert($0.prefix.count == len)
            }
        }
        #endif

        return map
    }()

    public private(set) var identifiers = [GS1CodeElement]()
    public private(set) var skipped = [String]()

    public init(_ code: String) {
        let (identifiers, skipped) = parse(code)
        self.identifiers = identifiers
        self.skipped = skipped
    }

}

// MARK: - accessors for often-used AIs
extension GS1Code {
    public var gtin: String? {
        return valueForAI("01")
    }

    func weight(in unit: Units) -> Decimal? {
        guard let rawWeight = firstDecimal(matching: "310"), unit.quantity == .mass else {
            return nil
        }

        switch unit {
        case .kilogram: return rawWeight
        case .hectogram: return rawWeight * Decimal(10)
        case .decagram: return rawWeight * Decimal(100)
        case .gram: return rawWeight * Decimal(1000)
        default: return nil
        }
    }

    var weight: Int? {
        return weight(in: .gram)?.intValue
    }

    func length(in unit: Units) -> Decimal? {
        guard let rawLength = firstDecimal(matching: "311"), unit.quantity == .distance else {
            return nil
        }

        switch unit {
        case .meter: return rawLength
        case .decimeter: return rawLength * Decimal(10)
        case .centimeter: return rawLength * Decimal(100)
        case .millimeter: return rawLength * Decimal(1000)
        default: return nil
        }
    }

    var length: Int? {
        return length(in: .millimeter)?.intValue
    }

    func area(in unit: Units) -> Decimal? {
        guard let rawArea = firstDecimal(matching: "314"), unit.quantity == .area else {
            return nil
        }

        switch unit {
        case .squareMeter: return rawArea
        case .squareMeterTenth: return rawArea * Decimal(10)
        case .squareDecimeter: return rawArea * Decimal(100)
        case .squareDecimeterTenth: return rawArea * Decimal(1000)
        case .squareCentimeter: return rawArea * Decimal(10000)
        default: return nil
        }
    }

    var area: Int? {
        return area(in: .squareCentimeter)?.intValue
    }

    func liters(in unit: Units) -> Decimal? {
        guard let rawLiters = firstDecimal(matching: "315"), unit.quantity == .volume else {
            return nil
        }

        switch unit {
        case .liter: return rawLiters
        case .deciliter: return rawLiters * Decimal(10)
        case .centiliter: return rawLiters * Decimal(100)
        case .milliliter: return rawLiters * Decimal(1000)
        default: return nil
        }
    }

    var liters: Int? {
        return liters(in: .milliliter)?.intValue
    }

    func volume(in unit: Units) -> Decimal? {
        guard let rawVolume = firstDecimal(matching: "316"), unit.quantity == .capacity else {
            return nil
        }

        switch unit {
        case .cubicMeter: return rawVolume
        case .cubicCentimeter: return rawVolume * Decimal(1_000_000)
        default: return nil
        }
    }

    var volume: Int? {
        return volume(in: .cubicCentimeter)?.intValue
    }

    var amount: Int? {
        guard let amount = valueForAI("30") else {
            return nil
        }
        return Int(amount)
    }

    var price: (price: Decimal, currency: String?)? {
        // try "amount payable (single monetary area)" first
        if let price = firstDecimal(matching: "392") {
            return (price, nil)
        }

        // try "amount payable with ISO currency code"
        if let priceAI = firstElement(matching: "393"), let price = priceAI.decimal {
            return (price, priceAI.values[0])
        }

        return nil
    }

    func price(_ digits: Int, _ roundingMode: RoundingMode) -> Int? {
        guard let priceData = self.price else {
            return nil
        }

        let price = priceData.price
        let newPrice: Decimal
        if price.exponent <= 0 {
            newPrice = price * pow(Decimal(10), digits)
        } else {
            newPrice = price * pow(Decimal(10), digits - price.exponent)
        }

        return newPrice.rounded(mode: roundingMode).intValue
    }

    public func getEmbeddedData(for encodingUnit: Units?, _ digits: Int, _ roundingMode: RoundingMode) -> (Int?, Units?) {
        guard let encodingUnit = encodingUnit else {
            return (nil, nil)
        }

        switch encodingUnit.quantity {
        case .volume: return (self.liters, .milliliter)
        case .capacity: return (self.volume, .cubicCentimeter)
        case .area: return (self.area, .squareCentimeter)
        case .distance: return (self.length, .millimeter)
        case .mass: return (self.weight, .gram)
        case .count: return (self.amount, .piece)
        case .amount: return (self.price(digits, roundingMode), .price)
        }
    }

    private func firstDecimal(matching prefix: String) -> Decimal? {
        return firstElement(matching: prefix)?.decimal
    }

    private func firstElement(matching prefix: String) -> GS1CodeElement? {
        for digit in (0...5).reversed() {
            let ai = "\(prefix)\(digit)"
            let match = self.identifiers.first { $0.definition.prefix == ai }
            if let identifier = match {
                return identifier
            }
        }

        return nil
    }

    private func valueForAI(_ ai: String) -> String? {
        return self.identifiers.first(where: { $0.definition.prefix == ai })?.values[0]
    }
}

// MARK: - parsing methods
extension GS1Code {
    static let symbologyIdentifiers = [
        "]C1",  // = GS1-128
        "]e0",  // = GS1 DataBar
        "]d2",  // = GS1 DataMatrix
        "]Q3",  // = GS1 QR Code
        "]J1"   // = GS1 DotCode
    ]

    private func parse(_ code: String) -> ([GS1CodeElement], [String]) {
        var code = code
        var identifiers = [GS1CodeElement]()
        var skipped = [String]()

        for symId in Self.symbologyIdentifiers where code.hasPrefix(symId) {
            code.removeFirst(symId.count)
        }

        while !code.isEmpty {
            while code.hasPrefix(Self.gs) {
                code.removeFirst()
            }

            let prefix = String(code.prefix(2))
            if let candidates = Self.prefixMap[prefix], let candidate = findCandidate(candidates, code) {
                if let (len, values) = self.matchCandidate(candidate, code) {
                    code.removeFirst(len)
                    let ai = GS1CodeElement(definition: candidate, values: values)
                    identifiers.append(ai)
                } else {
                    let skip = skipToNext(&code)
                    // print("unmatched pattern \(candidate.regex.pattern) - skipping over \(skip) to next FNC1")
                    skipped.append(skip)
                }
            } else {
                let skip = skipToNext(&code)
                // print("unknown prefix - skipping over \(skip) to next FNC1")
                skipped.append(skip)
            }
        }

        return (identifiers, skipped)
    }

    private func skipToNext(_ code: inout String) -> String {
        let prefix = String(code.prefix(2))
        if let length = ApplicationIdentifier.predefinedLengths[prefix] {
            let skipped = code.prefix(length)
            code.removeFirst(min(code.count, length))
            return String(skipped)
        } else {
            // skip until next separator
            var skipped = [Character]()
            while !code.hasPrefix(Self.gs) && !code.isEmpty {
                skipped.append(code.removeFirst())
            }
            return String(skipped)
        }
    }

    private func findCandidate(_ candidates: [ApplicationIdentifier], _ code: String) -> ApplicationIdentifier? {
        if candidates.count == 1 {
            return candidates[0]
        }

        for ai in candidates where code.hasPrefix(ai.prefix) {
            return ai
        }
        return nil
    }

    private func matchCandidate(_ ai: ApplicationIdentifier, _ code: String) -> (Int, [String])? {
        var len = 0
        var values = [String]()

        let matches = ai.regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.count))
        if !matches.isEmpty && matches[0].numberOfRanges > 1 {
            for idx in 1 ..< matches[0].numberOfRanges {
                let range = matches[0].range(at: idx)
                let startIndex = code.index(code.startIndex, offsetBy: range.lowerBound)
                let endIndex = code.index(code.startIndex, offsetBy: range.upperBound)
                let substr = String(code[startIndex..<endIndex])
                // print("found match: \(ai.name) \(substr)")
                len += substr.count
                values.append(substr)
            }
            len += ai.prefix.count
        } else {
            return nil
        }

        return (len, values)
    }
}
