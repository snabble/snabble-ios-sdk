//
//  IBAN.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

extension String {
    public func firstIndexOf(charactersIn string: String) -> Index? {
        let index = self.firstIndex { (character) -> Bool in
            if let unicodeScalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 {
                return CharacterSet(charactersIn: string).contains(unicodeScalar)
            }
            return false
        }
        return index
    }
}

// sample IBANs from https://www.iban.com/structure
// DE75512108001245126199
// NL02ABNA0123456789

/**
 Supported official IBAN (ISO 13616) formats see:
 https://de.wikipedia.org/wiki/Internationale_Bankkontonummer#IBAN-Struktur_in_verschiedenen_Ländern
 To give a user a hint while typing, the format string contains special characters:

 p  Prüfsumme
 b   Stelle der Bankleitzahl 
 d   Kontotyp 
 k   Stelle der Kontonummer 
 K   Kontrollzeichen (Großbuchstabe oder Ziffer) 
 r   Regionalcode 
 s   Stelle der Filialnummer (Branch Code / code guichet) 
 X   sonstige Funktionen
 */

/**
 Length and formatting info for SEPA IBANs see:
 https://en.wikipedia.org/wiki/International_Bank_Account_Number#IBAN_formats_by_country

 ISO 13616 IBAN formats see (page 6):
 https://www.swift.com/resource/iban-registry-pdf
 
 The following character representations are used to choose the corresponding soft keyboard:
 n - Digits (numeric characters 0 to 9 only)
 a - Upper case letters (alphabetic characters A-Z only)
 c - upper and lower case alphanumeric characters (A-Z, a-z and 0-9)
 e - blank space

 The following length indications are used:
 nn! fixedlength
 nn maximum length
 */

public enum IBAN {
    // swiftlint:disable large_tuple
    private static let info: [String: (length: Int, mapping: [String], format: String)] = [
        "AD": (24, ["4!n", "4!n", "12!c"], "pp bbbb ssss kkkk kkkk kkkk"),
        "AT": (20, ["5!n", "11!n"], "pp bbbb bkkk kkkk kkkk"),
        "BE": (16, ["3!n", "7!n", "2!n"], "pp bbbk kkkk kkKK"),
        "BG": (22, ["4!a", "4!n", "2!n", "8!c"], "pp bbbb ssss ddkk kkkk kk"),
        "CH": (21, ["5!n", "12!c"], "pp bbbb bkkk kkkk kkkk k"),
        "CY": (28, ["3!n", "5!n", "16!c"], "pp bbbs ssss kkkk kkkk kkkk kkkk"),
        "CZ": (24, ["4!n", "6!n", "10!n"], "pp bbbb kkkk kkkk kkkk kkkk"),
        "DE": (22, ["8!n", "10!n"], "pp bbbb bbbb kkkk kkkk kk"),
        "DK": (18, ["4!n", "9!n", "1!n"], "pp bbbb kkkk kkkk kK"),
        "EE": (20, ["2!n", "2!n", "11!n", "1!n"], "pp bbkk kkkk kkkk kkkK"),
        "ES": (24, ["4!n", "4!n", "1!n", "1!n", "10!n"], "pp bbbb ssss KKkk kkkk kkkk"),
        "FI": (18, ["3!n", "11!n"], "pp bbbb bbkk kkkk kK"),
        "FO": (18, ["4!n", "9!n", "1!n"], "pp bbbb kkkk kkkk kK"),
        "FR": (27, ["5!n", "5!n", "11!c", "2!n"], "pp bbbb bsss sskk kkkk kkkk kKK"),
        "GB": (22, ["4!a", "6!n", "8!n"], "pp bbbb ssss sskk kkkk kk"),
        "GI": (23, ["4!a", "15!c"], "pp bbbb kkkk kkkk kkkk kkk"),
        "GL": (18, ["4!n", "9!n", "1!n"], "pp bbbb kkkk kkkk kK"),
        "GR": (27, ["3!n", "4!n", "16!c"], "pp bbbs sssk kkkk kkkk kkkk kkk"),
        "HR": (21, ["7!n", "10!n"], "pp bbbb bbbk kkkk kkkk k"),
        "HU": (28, ["3!n", "4!n", "1!n", "15!n", "1!n"], "pp bbbs sssK kkkk kkkk kkkk kkkK"),
        "IE": (22, ["4!a", "6!n", "8!n"], "pp bbbb ssss sskk kkkk kk"),
        "IS": (26, ["4!n", "2!n", "6!n", "10!n"], "pp bbbb sskk kkkk XXXX XXXX XX"),
        "IT": (27, ["1!a", "5!n", "5!n", "12!c"], "pp Kbbb bbss sssk kkkk kkkk kkk"),
        "LI": (21, ["5!n", "12!c"], "pp bbbb bkkk kkkk kkkk k"),
        "LT": (20, ["5!n", "11!n"], "pp bbbb bkkk kkkk kkkk"),
        "LU": (20, ["3!n", "13!c"], "pp bbbk kkkk kkkk kkkk"),
        "LV": (21, ["4!a", "13!c"], "pp bbbb kkkk kkkk kkkk k"),
        "MC": (27, ["5!n", "5!n", "11!c", "2!n"], "pp bbbb bsss sskk kkkk kkkk kKK"),
        "MT": (31, ["4!a", "5!n", "18!c"], "pp bbbb ssss skkk kkkk kkkk kkkk kkk"),
        "NL": (18, ["4!a", "10!n"], "pp bbbb kkkk kkkk kk"),
        "NO": (15, ["4!n", "6!n", "1!n"], "pp bbbb kkkk kkK"),
        "PL": (28, ["8!n", "16!n"], "pp bbbs sssK kkkk kkkk kkkk kkkk"),
        "PT": (25, ["4!n", "4!n", "11!n", "2!n"], "pp bbbb ssss kkkk kkkk kkkK K"),
        "RO": (24, ["4!a", "16!c"], "pp bbbb kkkk kkkk kkkk kkkk"),
        "SE": (24, ["3!n", "16!n", "1!n"], "pp bbbk kkkk kkkk kkkk kkkK"),
        "SI": (19, ["5!n", "8!n", "2!n"], "pp bbss skkk kkkk kKK"),
        "SK": (24, ["4!n", "6!n", "10!n"], "pp bbbb ssss sskk kkkk kkkk"),
        "SM": (27, ["1!a", "5!n", "5!n", "12!c"], "pp Kbbb bbss sssk kkkk kkkk kkk"),
        "VA": (22, ["3!n", "15!n"], "pp bbbk kkkk kkkk kkkk kk")
    ]
    // swiftlint:enable large_tuple

    public enum ControlChar: String {
        case digits = "n"
        case uppercaseLetters = "a"
        case alphanumerics = "c"
        case space = "e"
    }

    public static func keyboardMapping(_ country: String) -> String {
        guard let mapping = self.info[country]?.mapping, let length = length(country) else {
            fatalError("invalid country: \(country)")
        }
        var string = String("\(country)nn")
        var counter = string.count
        
        for item in mapping {
            func split() -> (count: Int, control: ControlChar)? {
                if let countIndex = item.firstIndexOf(charactersIn: "!nace"),
                   let count = Int(String(item.prefix(upTo: countIndex))),
                   let controlIndex = item.firstIndexOf(charactersIn: "nace"),
                   let controlChar = ControlChar(rawValue: String(item.suffix(from: controlIndex))) {
                    return (count, controlChar)
                }
                return nil
            }
            if let map = split() {
                for _ in 0..<map.count {
                    string.append(map.control.rawValue)
                }
                counter += map.count
            }
        }
        if length != counter {
            print("warning different length: \(length) from keymapping -> \(counter) (\(string)")
        }
        let pretty = IBAN.prettyPrint(string)
        return String(pretty.suffix(pretty.count - 2))
    }

    public static let formatCharacters: [Character] = ["p", "b", "d", "k", "K", "r", "s", "X"]
    public static let formatKeys: String = { formatCharacters.reduce("", { "\($0)\($1)" }) }()  // "pbdkKrsX"

    public static var formatCharacterSet: CharacterSet {
        return CharacterSet(charactersIn: formatKeys)
    }

    public static func formatString(_ country: String) -> String {
        guard let string = self.info[country]?.format, let length = length(country) else {
            fatalError("invalid country: \(country)")
        }
        let offset = string.count - string.replacingOccurrences(of: " ", with: "").count
        return String(string.prefix(length + offset - 2))
    }

    public static func placeholder(_ country: String, with placeholderChar: Character = "•") -> String {
        var result = formatString(country)
        for char in formatCharacters {
            result = result.replacingOccurrences(of: String(char), with: String(placeholderChar))
        }
        return result
    }

    public static var countries: [String] {
        return info.keys.compactMap({ $0 })
    }

    public static func length(_ country: String) -> Int? {
        return info[country]?.length
    }

    public static func displayName(_ iban: String) -> String {
        let country = String(iban.prefix(2))
        let prefix = String(iban.prefix(4))
        let suffix = String(iban.suffix(2))

        guard length(country) != nil else {
            let len = max(iban.count - 6, 0)
            let dots = String(repeating: "•", count: len)
            return prefix + " " + dots + " " + suffix
        }
        let placeholder = IBAN.placeholder(country)
        let start = placeholder.index(placeholder.startIndex, offsetBy: 2)
        let end = placeholder.index(placeholder.endIndex, offsetBy: -2)

        return prefix + String(placeholder[start..<end]) + suffix
    }

    public static func validCharacterSet(_ country: String) -> CharacterSet {
        var charset = CharacterSet(charactersIn: "0123456789 ")
        
        let mapping = keyboardMapping(country)

        if mapping.contains(where: { $0 == Character(ControlChar.uppercaseLetters.rawValue) }) {
            charset.formUnion(.uppercaseLetters)
        }
        if mapping.contains(where: { $0 == Character(ControlChar.alphanumerics.rawValue) }) {
            charset.formUnion(.alphanumerics)
        }
        return charset
    }

    // see https://en.wikipedia.org/wiki/International_Bank_Account_Number#Modulo_operation_on_IBAN
    public static func verify(iban: String) -> Bool {
        
        var rawBytes = Array(iban.replacingOccurrences(of: " ", with: "").utf8)
        while rawBytes.count < 4 {
            rawBytes.append(0)
        }

        let bytes = rawBytes[4 ..< rawBytes.count] + rawBytes[0 ..< 4]

        let check = bytes.reduce(0) { result, digit in
            let int = Int(digit)
            return int > 64 ? (100 * result + int - 55) % 97 : (10 * result + int - 48) % 97
        }

        return check == 1
    }
}

extension IBAN {
    public static func countryName(_ country: String) -> String? {
        return Locale.current.localizedString(forRegionCode: country)
    }
}

extension IBAN {
    public static func prettyPrint(_ iban: String) -> String {
        let iban = iban.replacingOccurrences(of: " ", with: "")
        let country = String(iban.prefix(2))
        let placeholder = IBAN.placeholder(country)

        guard placeholder.replacingOccurrences(of: " ", with: "").count == iban.count - 2 else {
            return iban
        }

        var offset: Int = 4
        let prefix = String(iban.prefix(offset))

        let start = placeholder.index(placeholder.startIndex, offsetBy: 2)
        var result = prefix

        for char in String(placeholder[start...]) {
            if char == " " {
                result.append(" ")
            } else {
                let currentIndex = iban.index(iban.startIndex, offsetBy: offset)
                result.append(String(iban[currentIndex]))
                offset += 1
            }
        }
        return result
    }
}

public struct IBANDefinition {
    public let country: String
    public let formatString: String
    public let placeholder: String
    public let keyboardMapping: String

    public init(country: String) {
        self.country = country

        self.formatString = IBAN.formatString(country)
        self.placeholder = IBAN.placeholder(country)
        self.keyboardMapping = IBAN.keyboardMapping(country)
    }
}
