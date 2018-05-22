//
//  EAN.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//


/// a generic EAN code (EAN-8 or EAN-13)
public protocol EANCode {
    /// the full code, including the check digit
    var code: String { get }

    /// the check digit as an Int
    var checkDigit: Int { get }

    /// the encoding (EAN-8 or EAN-13)
    var encoding: EAN.Encoding { get }
}

extension EANCode {
    /// the check digit as an Int
    public var checkDigit: Int {
        let last = code.suffix(1)
        return Int(last)!
    }

    // MARK: - check for embedded data
    public var hasEmbeddedWeight: Bool {
        return self.encoding == .ean13 && self.matchPrefixes(APIConfig.shared.project.weighPrefixes)
    }

    public var hasEmbeddedPrice: Bool {
        return self.encoding == .ean13 && self.matchPrefixes(APIConfig.shared.project.pricePrefixes)
    }

    public var hasEmbeddedUnits: Bool {
        return self.encoding == .ean13 && self.matchPrefixes(APIConfig.shared.project.unitPrefixes)
    }

    public var hasEmbeddedData: Bool {
        return self.hasEmbeddedWeight || self.hasEmbeddedPrice || self.hasEmbeddedUnits
    }

    // MARK: - get embedded data
    public var embeddedWeight: Int? {
        return self.hasEmbeddedWeight ? self.rawEmbeddedData : nil
    }

    public var embeddedPrice: Int? {
        return self.hasEmbeddedPrice ? self.rawEmbeddedData : nil
    }

    public var embeddedUnits: Int? {
        return self.hasEmbeddedUnits ? self.rawEmbeddedData : nil
    }

    public var embeddedData: Int? {
        return self.hasEmbeddedData ? self.rawEmbeddedData : nil
    }

    // MARK: - get a code suitable for lookup (i.e. with the last 5 data digits and the checksum digits as 0)
    public var codeForLookup: String {
        switch self.encoding {
        case .ean13:
            if self.hasEmbeddedData {
                return self.code.prefix(7) + "000000"
            } else {
                return code
            }
        case .ean8:
            return code
        }
    }

    private var rawEmbeddedData: Int? {
        switch self.encoding {
        case .ean13:
            let start = self.code.index(code.startIndex, offsetBy: 7)
            let end = self.code.index(code.startIndex, offsetBy: 12)
            let data = self.code[start ..< end]
            return Int(data)
        case .ean8:
            return nil
        }
    }

    private func matchPrefixes(_ prefixes: [String]) -> Bool {
        guard prefixes.count > 0 else {
            return false
        }

        for prefix in prefixes {
            if self.code.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }
}


/// methods for parsing and encoding an EAN-8 or EAN-13
public enum EAN {

    public enum Encoding {
        case ean8
        case ean13
    }

    /// parse an EAN-8 or EAN-13.
    ///
    /// - Parameter code: the EAN code.
    ///   This must be a 7 or 8 digit string for EAN-8, or a 12 or 13 digit string for EAN-13
    ///
    ///   if the code has 8 or 13 digits, the last digit is checked to be the correct check digit for this code.
    ///   if the code has 7 or 12 digits, the check digit for this code is calculated and appended to the code.
    /// - Returns: an EANCode, or nil if the code did not represent a well-formed EAN-8 or EAN-13
    public static func parse(_ code: String) -> EANCode? {
        switch code.count {
        case 7, 8: return EAN8(code)
        case 12, 13: return EAN13(code)
        default: return nil
        }
    }

    /// calculate the check digit for a given EAN-8 or EAN-13 code
    ///
    /// - Parameter code: the EAN code. Must have 7, 8, 12, or 13 digits.
    /// - Returns: the check digit, or nil if the code did not represent a well-formed EAN-8 or EAN-13
    public static func checkDigit(for code: String) -> Int? {
        switch code.count {
        case 7, 8: return EAN8.checkDigit(for: code)
        case 12, 13: return EAN13.checkDigit(for: code)
        default: return nil
        }
    }

    public typealias Bits = [Int]

    /// encode an EAN-8 or EAN-13 as individual bits
    ///
    /// - Parameter code: an EAN-8 or EAN-13 code.
    /// - Returns: an array of `Int`s, representing the bitwise encoding of the EAN, or nil
    ///   if code did not represent a well-formed EAN-8 or EAN-13
    public static func encode(_ code: String) -> Bits? {
        switch code.count {
        case 13: return encode13(code)
        case 8: return encode8(code)
        default: return nil
        }
    }
}

// MARK: - EAN-8
public struct EAN8: EANCode {
    public let code: String
    public let encoding = EAN.Encoding.ean8

    let leftDigits: [Int]
    let rightDigits: [Int]

    /// create an EAN8
    ///
    /// - Parameter code: a 7 or 8 digit string represening an EAN-8
    /// - Returns: an EAN8 object, or nil if `code` did not represent an EAN-8
    public init?(_ code: String) {
        guard code.count == 8 || code.count == 7, Int64(code) != nil else {
            return nil
        }

        let digits = code.compactMap { Int(String($0)) }

        guard let check = EAN8.checkDigit(for: digits) else {
            return nil
        }

        if code.count == 8 && check != digits[7] {
            return nil
        }

        self.leftDigits = Array(digits[0...3])
        self.rightDigits = Array(digits[4...min(code.count-1, 7)])

        self.code = code.prefix(7) + String(check)
    }

    /// calculate the check digit for an EAN-8
    ///
    /// - Parameter code: a 7 or 8 digit string representing an EAN-8
    /// - Returns: the check digit for that EAN-8, or nil if `code` is not a valid EAN-8
    public static func checkDigit(for code: String) -> Int? {
        let digits = code.map { Int(String($0)) ?? 0 }
        return self.checkDigit(for: digits)
    }

    static func checkDigit(for digits: [Int]) -> Int? {
        guard digits.count > 6 else {
            return nil
        }

        let sum1 = digits[1] + digits[3] + digits[5]
        let sum2 = digits[0] + digits[2] + digits[4] + digits[6]

        let mod10 = (sum1 + 3 * sum2) % 10
        let check = (10 - mod10) % 10
        return check
    }
}

// MARK: - EAN-13

public struct EAN13: EANCode {
    public let code: String
    public let encoding = EAN.Encoding.ean13

    let firstDigit: Int
    let leftDigits: [Int]
    let rightDigits: [Int]

    /// create an EAN13
    ///
    /// - Parameter code: a 12 or 13 digit string represening an EAN-13
    /// - Returns: an EAN13 object, or nil if `code` did not represent an EAN-13
    public init?(_ code: String) {
        guard code.count == 13 || code.count == 12, Int64(code) != nil else {
            return nil
        }

        let digits = code.map { Int(String($0)) ?? 0 }

        guard let check = EAN13.checkDigit(for: digits) else {
            return nil
        }
        if code.count == 13 && check != digits[12] {
            return nil
        }

        self.firstDigit = digits[0]
        self.leftDigits = Array(digits[1...6])
        self.rightDigits = Array(digits[7...min(code.count-1, 11)])

        self.code = code.prefix(12) + String(check)
    }

    /// calculate the check digit for an EAN-13
    ///
    /// - Parameter code: a 12 or 13 digit string representing an EAN-13
    /// - Returns: the check digit for that EAN-8, or nil if `code` is not a valid EAN-13
    public static func checkDigit(for code: String) -> Int? {
        let digits = code.map { Int(String($0)) ?? 0 }
        return self.checkDigit(for: digits)
    }

    static func checkDigit(for digits: [Int]) -> Int? {
        guard digits.count > 11 else {
            return nil
        }
        let sum1 = digits[1] + digits[3] + digits[5] + digits[7] + digits[9] + digits[11]
        let sum2 = digits[0] + digits[2] + digits[4] + digits[6] + digits[8] + digits[10]

        let mod10 = (3 * sum1 + sum2) % 10
        let check = (10 - mod10) % 10
        return check
    }

}

// MARK: - bitwise encoding

extension EAN {

    /// encode an EAN-13 as individual bits
    ///
    /// - Parameter code: an EAN-13 code.
    /// - Returns: an array of `Int`s, representing the bitwise encoding of the EAN, or nil
    ///   if `code` did not represent a well-formed EAN-13
    public static func encode13(_ code: String) -> Bits? {
        guard let ean = EAN13(code) else {
            return nil
        }
        return encode13(ean)
    }

    static func encode13(_ ean: EAN13) -> Bits {
        var bits = Bits()

        bits.append(contentsOf: EANBits.blankBits)
        bits.append(contentsOf: EANBits.borderBits)

        let parity = EANBits.parityBits[ean.firstDigit]
        for (index, digit) in ean.leftDigits.enumerated() {
            let arr = parity[index] == 0 ? EANBits.oddLeftBits : EANBits.evenLeftBits
            bits.append(contentsOf: arr[digit])
        }

        bits.append(contentsOf: EANBits.separatorBits)

        for digit in ean.rightDigits {
            bits.append(contentsOf: EANBits.rightBits[digit])
        }

        bits.append(contentsOf: EANBits.borderBits)
        bits.append(contentsOf: EANBits.blankBits)

        return bits
    }

    /// encode an EAN-8 as individual bits
    ///
    /// - Parameter code: an EAN-8 code.
    /// - Returns: an array of `Int`s, representing the bitwise encoding of the EAN, or nil
    ///   if `code` did not represent a well-formed EAN-8
    public static func encode8(_ code: String) -> Bits? {
        guard let ean = EAN8(code) else {
            return nil
        }
        return encode8(ean)
    }

    static func encode8(_ ean: EAN8) -> Bits {
        var bits = Bits()

        bits.append(contentsOf: EANBits.blankBits)
        bits.append(contentsOf: EANBits.borderBits)

        for digit in ean.leftDigits {
            bits.append(contentsOf: EANBits.oddLeftBits[digit])
        }

        bits.append(contentsOf: EANBits.separatorBits)

        for digit in ean.rightDigits {
            bits.append(contentsOf: EANBits.rightBits[digit])
        }

        bits.append(contentsOf: EANBits.borderBits)
        bits.append(contentsOf: EANBits.blankBits)

        return bits
    }
}

/// various bit constants for EAN encoding
/// see https://en.wikipedia.org/wiki/International_Article_Number#How_the_13-digit_EAN-13_is_encoded
struct EANBits {
    static let blankBits = [0,0,0,0,0,0,0,0,0]
    static let borderBits = [1,0,1]
    static let separatorBits = [0,1,0,1,0]
    static let oddLeftBits = [
        [0,0,0,1,1,0,1], [0,0,1,1,0,0,1], [0,0,1,0,0,1,1], [0,1,1,1,1,0,1], [0,1,0,0,0,1,1],
        [0,1,1,0,0,0,1], [0,1,0,1,1,1,1], [0,1,1,1,0,1,1], [0,1,1,0,1,1,1], [0,0,0,1,0,1,1]
    ]
    static let evenLeftBits = [
        [0,1,0,0,1,1,1], [0,1,1,0,0,1,1], [0,0,1,1,0,1,1], [0,1,0,0,0,0,1], [0,0,1,1,1,0,1],
        [0,1,1,1,0,0,1], [0,0,0,0,1,0,1], [0,0,1,0,0,0,1], [0,0,0,1,0,0,1], [0,0,1,0,1,1,1]
    ]
    static let rightBits = [
        [1,1,1,0,0,1,0], [1,1,0,0,1,1,0], [1,1,0,1,1,0,0], [1,0,0,0,0,1,0], [1,0,1,1,1,0,0],
        [1,0,0,1,1,1,0], [1,0,1,0,0,0,0], [1,0,0,0,1,0,0], [1,0,0,1,0,0,0], [1,1,1,0,1,0,0]
    ]
    static let parityBits = [
        [0,0,0,0,0,0], [0,0,1,0,1,1], [0,0,1,1,0,1], [0,0,1,1,1,0], [0,1,0,0,1,1],
        [0,1,1,0,0,1], [0,1,1,1,0,0], [0,1,0,1,0,1], [0,1,0,1,1,0], [0,1,1,0,1,0]
    ]
}
