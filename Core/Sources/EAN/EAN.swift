//
//  EAN.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

/// a generic EAN code (EAN-8, EAN-13 or EAN-14)
public protocol EANCode {
    /// the full code, including the check digit
    var code: String { get }

    /// the digits of the code, including the check digit
    var digits: [Int] { get }

    /// the check digit as an Int
    var checkDigit: Int { get }

    /// the encoding (EAN-8, EAN-13 or EAN-14)
    var encoding: EAN.Encoding { get }
}

extension EANCode {
    /// the check digit as an Int
    public var checkDigit: Int {
        return self.digits.last ?? 0
    }
}

/// methods for parsing and encoding an EAN-8, EAN-13 or EAN-14
public enum EAN {
    public enum Encoding {
        case ean8
        case ean13
        case ean14
    }

    /// parse an EAN-8, EAN-13 or EAN-14
    ///
    /// - Parameter code: the EAN code.
    ///   This must be a
    ///   - 7 or 8 digit string for EAN-8
    ///   - 12 or 13 digit string for EAN-13
    ///   - 14 or 16 digit string for EAN-14
    ///
    ///   if `code` has 8, 13 or 14 digits, the last digit is checked to be the correct check digit for this code.
    ///   if `code` has 7 or 12 digits, the check digit for this code is calculated and appended to the code.
    ///   if `code` has 16 digits, it is treated as an EAN-14 embedded in a Code-128 (i.e, prefixed with "01")
    /// - Returns: an EANCode, or nil if the code did not represent a well-formed EAN-8, EAN-13 or EAN-14
    public static func parse(_ code: String) -> EANCode? {
        switch code.count {
        case 7, 8: return EAN8(code)
        case 12, 13: return EAN13(code)
        case 14, 16: return EAN14(code)
        default: return nil
        }
    }

    /// calculate the check digit for a given EAN-8, EAN-13 or EAN-14 code
    ///
    /// - Parameter code: the EAN code. Must have 7, 8, 12, 13 or 14 digits.
    /// - Returns: the check digit, or nil if the code did not represent a well-formed EAN-8, EAN-13 or EAN-14
    public static func checkDigit(for code: String) -> Int? {
        switch code.count {
        case 7, 8: return EAN8.checkDigit(for: code)
        case 12, 13: return EAN13.checkDigit(for: code)
        case 14: return EAN14.checkDigit(for: code)
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
        case 13:
            return encode13(code)
        case 8:
            return encode8(code)
        default: return nil
        }
    }
}

// MARK: - EAN-8
public struct EAN8: EANCode {
    public let code: String
    public let encoding = EAN.Encoding.ean8
    public let digits: [Int]

    /// create an EAN8
    ///
    /// - Parameter code: a 7 or 8 digit string representing an EAN-8
    /// - Returns: an EAN8 object, or nil if `code` did not represent an EAN-8
    public init?(_ code: String) {
        guard
            code.count == 8 || code.count == 7,
            Int64(code) != nil,
            let check = EAN8.checkDigit(for: code),
            code.count == 8 ? String(check) == String(code.suffix(1)) : true
        else {
            return nil
        }

        self.code = code.prefix(7) + String(check)
        self.digits = self.code.compactMap { Int(String($0)) }
    }

    /// calculate the check digit for an EAN-8
    ///
    /// - Parameter code: a 7 or 8 digit string representing an EAN-8
    /// - Returns: the check digit for that EAN-8, or nil if `code` is not a valid EAN-8
    public static func checkDigit(for code: String) -> Int? {
        let digits = code.compactMap { Int(String($0)) }
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
    public let digits: [Int]

    /// create an EAN13
    ///
    /// - Parameter code: a 12 or 13 digit string representing an EAN-13
    /// - Returns: an EAN13 object, or nil if `code` did not represent an EAN-13
    public init?(_ code: String) {
        guard
            code.count == 13 || code.count == 12,
            Int64(code) != nil,
            let check = EAN13.checkDigit(for: code),
            code.count == 13 ? String(check) == String(code.suffix(1)) : true
        else {
            return nil
        }

        self.code = code.prefix(12) + String(check)
        self.digits = self.code.compactMap { Int(String($0)) }
    }

    /// calculate the check digit for an EAN-13
    ///
    /// - Parameter code: a 12 or 13 digit string representing an EAN-13
    /// - Returns: the check digit for that EAN-13, or nil if `code` is not a valid EAN-13
    public static func checkDigit(for code: String) -> Int? {
        let digits = code.compactMap { Int(String($0)) }
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

// MARK: - price/weight check digit

extension EAN13 {
    // calculate the internal checksum for a 5-digit price/weight data field
    func internalChecksum5() -> Int {
        return EAN13.internalChecksum5(Array(self.digits[7 ... 11]))
    }

    static func internalChecksum5(_ digits: [Int]) -> Int {
        let sum = digits.enumerated().reduce(0) { $0 + EAN13.weightedProduct5digits($1.0, $1.1) }
        let mod10 = (10 - (sum % 10)) % 10
        let check = EAN13.check5minusReverse[mod10] ?? -1
        return check
    }

    // calculate the internal checksum for a 4-digit price/weight data field
    func internalChecksum4() -> Int {
        let sum = self.digits[8 ... 11].enumerated().reduce(0) { $0 + EAN13.weightedProduct4digits($1.0, $1.1) }
        let check = (sum * 3) % 10
        return check
    }

    private static let check2minus = [ 0: 0, 1: 2, 2: 4, 3: 6, 4: 8, 5: 9, 6: 1, 7: 3, 8: 5, 9: 7 ]
    private static let check3      = [ 0: 0, 1: 3, 2: 6, 3: 9, 4: 2, 5: 5, 6: 8, 7: 1, 8: 4, 9: 7 ]
    private static let check5plus  = [ 0: 0, 1: 5, 2: 1, 3: 6, 4: 2, 5: 7, 6: 3, 7: 8, 8: 4, 9: 9 ]
    private static let check5minus = [ 0: 0, 1: 5, 2: 9, 3: 4, 4: 8, 5: 3, 6: 7, 7: 2, 8: 6, 9: 1 ]
    private static let check5minusReverse = Dictionary(uniqueKeysWithValues: check5minus.map { ($1, $0) })

    private static func weightedProduct5digits(_ index: Int, _ digit: Int) -> Int {
        switch index {
        case 0, 3: return EAN13.check5plus[digit] ?? -1
        case 1, 4: return EAN13.check2minus[digit] ?? -1
        case 2: return EAN13.check5minus[digit] ?? -1
        default: return -1
        }
    }

    private static func weightedProduct4digits(_ index: Int, _ digit: Int) -> Int {
        switch index {
        case 0, 1: return EAN13.check2minus[digit] ?? -1
        case 2: return EAN13.check3[digit] ?? -1
        case 3: return EAN13.check5minus[digit] ?? -1
        default: return -1
        }
    }

    public static func embedDataInEan(_ template: String, data: Int) -> String {
        assert(data < 99999)

        let str = String(data)
        let padding = String(repeating: "0", count: 5 - str.count)
        let dataString = padding + str

        let code = String(template.prefix(6)) + "0" + dataString

        guard let ean = EAN13(code) else {
            return ""
        }

        let internalCheck = ean.internalChecksum5()
        let newCode = String(ean.code.prefix(6)) + String(internalCheck) + dataString
        let newEan = EAN13(newCode)
        return newEan?.code ?? ""
    }
}

// MARK: - EAN-14
public struct EAN14: EANCode {
    public let code: String
    public let encoding = EAN.Encoding.ean14
    public let digits: [Int]

    /// create an EAN14
    ///
    /// - Parameter code: a 14 digit string representing an EAN-14
    /// - Returns: an EAN14 object, or nil if `code` did not represent an EAN-14
    public init?(_ code: String) {
        guard
            code.count == 14,
            Int64(code) != nil,
            let check = EAN14.checkDigit(for: code),
            String(check) == String(code.suffix(1))
        else {
            return nil
        }

        self.code = code
        self.digits = self.code.compactMap { Int(String($0)) }
    }

    /// calculate the check digit for an EAN-14
    ///
    /// - Parameter code: a 14 digit string representing an EAN-14
    /// - Returns: the check digit for that EAN-14, or nil if `code` is not a valid EAN-14
    public static func checkDigit(for code: String) -> Int? {
        let digits = code.compactMap { Int(String($0)) }
        guard digits.count > 13 else {
            return nil
        }

        let sum1 = digits[1] + digits[3] + digits[5] + digits[7] + digits[9] + digits[11]
        let sum2 = digits[0] + digits[2] + digits[4] + digits[6] + digits[8] + digits[10] + digits[12]

        let mod10 = (sum1 + 3 * sum2) % 10
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

        let parity = EANBits.parityBits[ean.digits[0]]
        for (index, digit) in ean.digits[1...6].enumerated() {
            let arr = parity[index] == 0 ? EANBits.oddLeftBits : EANBits.evenLeftBits
            bits.append(contentsOf: arr[digit])
        }

        bits.append(contentsOf: EANBits.separatorBits)

        for digit in ean.digits[7...12] {
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

        for digit in ean.digits[0...3] {
            bits.append(contentsOf: EANBits.oddLeftBits[digit])
        }

        bits.append(contentsOf: EANBits.separatorBits)

        for digit in ean.digits[4...7] {
            bits.append(contentsOf: EANBits.rightBits[digit])
        }

        bits.append(contentsOf: EANBits.borderBits)
        bits.append(contentsOf: EANBits.blankBits)

        return bits
    }
}

/// various bit constants for EAN encoding
/// see https://en.wikipedia.org/wiki/International_Article_Number#How_the_13-digit_EAN-13_is_encoded
enum EANBits {
    static let blankBits = [0, 0, 0, 0, 0, 0, 0, 0, 0]
    static let borderBits = [1, 0, 1]
    static let separatorBits = [0, 1, 0, 1, 0]
    static let oddLeftBits = [
        [0, 0, 0, 1, 1, 0, 1], [0, 0, 1, 1, 0, 0, 1], [0, 0, 1, 0, 0, 1, 1], [0, 1, 1, 1, 1, 0, 1], [0, 1, 0, 0, 0, 1, 1],
        [0, 1, 1, 0, 0, 0, 1], [0, 1, 0, 1, 1, 1, 1], [0, 1, 1, 1, 0, 1, 1], [0, 1, 1, 0, 1, 1, 1], [0, 0, 0, 1, 0, 1, 1]
    ]
    static let evenLeftBits = [
        [0, 1, 0, 0, 1, 1, 1], [0, 1, 1, 0, 0, 1, 1], [0, 0, 1, 1, 0, 1, 1], [0, 1, 0, 0, 0, 0, 1], [0, 0, 1, 1, 1, 0, 1],
        [0, 1, 1, 1, 0, 0, 1], [0, 0, 0, 0, 1, 0, 1], [0, 0, 1, 0, 0, 0, 1], [0, 0, 0, 1, 0, 0, 1], [0, 0, 1, 0, 1, 1, 1]
    ]
    static let rightBits = [
        [1, 1, 1, 0, 0, 1, 0], [1, 1, 0, 0, 1, 1, 0], [1, 1, 0, 1, 1, 0, 0], [1, 0, 0, 0, 0, 1, 0], [1, 0, 1, 1, 1, 0, 0],
        [1, 0, 0, 1, 1, 1, 0], [1, 0, 1, 0, 0, 0, 0], [1, 0, 0, 0, 1, 0, 0], [1, 0, 0, 1, 0, 0, 0], [1, 1, 1, 0, 1, 0, 0]
    ]
    static let parityBits = [
        [0, 0, 0, 0, 0, 0], [0, 0, 1, 0, 1, 1], [0, 0, 1, 1, 0, 1], [0, 0, 1, 1, 1, 0], [0, 1, 0, 0, 1, 1],
        [0, 1, 1, 0, 0, 1], [0, 1, 1, 1, 0, 0], [0, 1, 0, 1, 0, 1], [0, 1, 0, 1, 1, 0], [0, 1, 1, 0, 1, 0]
    ]
}
