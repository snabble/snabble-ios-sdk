//
//  IBAN.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// sample IBANs from https://www.iban.com/structure
// DE75512108001245126199
// NL02ABNA0123456789

// length and formatting info for SEPA IBANs
// see https://en.wikipedia.org/wiki/International_Bank_Account_Number#IBAN_formats_by_country

public enum IBAN {
    private static let info: [String: (Int, String)] = [
        "AD": (24, "•• •••• •••• •••• •••• ••••"),
        "AT": (20, "•• •••• •••• •••• ••••"),
        "BE": (16, "•• •••• •••• ••••"),
        "BG": (22, "•• •••• •••• •••• •••• ••"),
        "HR": (21, "•• •••• •••• •••• •••• •"),
        "CY": (28, "•• •••• •••• •••• •••• •••• ••••"),
        "CZ": (24, "•• •••• •••• •••• •••• ••••"),
        "FO": (18, "•• •••• •••• •••• ••"),
        "GL": (18, "•• •••• •••• •••• ••"),
        "DK": (18, "•• •••• •••• •••• ••"),
        "EE": (20, "•• •••• •••• •••• ••••"),
        "FI": (18, "•• •••• •••• •••• ••"),
        "FR": (27, "•• •••• •••• •••• •••• •••• •••"),
        "DE": (22, "•• •••• •••• •••• •••• ••"),
        "GI": (23, "•• •••• •••• •••• •••• •••"),
        "GR": (27, "•• •••• •••• •••• •••• •••• •••"),
        "HU": (28, "•• •••• •••• •••• •••• •••• ••••"),
        "IS": (26, "•• •••• •••• •••• •••• •••• ••"),
        "IE": (22, "•• •••• •••• •••• •••• ••"),
        "IT": (27, "•• •••• •••• •••• •••• •••• •••"),
        "LV": (21, "•• •••• •••• •••• •••• •"),
        "LI": (21, "•• •••• •••• •••• •••• •"),
        "LT": (20, "•• •••• •••• •••• ••••"),
        "LU": (20, "•• •••• •••• •••• ••••"),
        "MT": (31, "•• •••• •••• •••• •••• •••• •••• •••"),
        "MC": (27, "•• •••• •••• •••• •••• •••• •••"),
        "NL": (18, "•• •••• •••• •••• ••"),
        "NO": (15, "•• •••• •••• •••"),
        "PL": (28, "•• •••• •••• •••• •••• •••• ••••"),
        "PT": (25, "•• •••• •••• •••• •••• •••• •"),
        "RO": (24, "•• •••• •••• •••• •••• ••••"),
        "SM": (27, "•• •••• •••• •••• •••• •••• •••"),
        "SK": (24, "•• •••• •••• •••• •••• ••••"),
        "SI": (19, "•• •••• •••• •••• •••"),
        "ES": (24, "•• •••• •••• •••• •••• ••••"),
        "SE": (24, "•• •••• •••• •••• •••• ••••"),
        "CH": (21, "•• •••• •••• •••• •••• •"),
        "GB": (22, "•• •••• •••• •••• •••• ••"),
        "VA": (22, "•• •••• •••• •••• •••• ••")
    ]

    public static var countries: [String] {
        return info.keys.compactMap({ $0 })
    }

    public static func length(_ country: String) -> Int? {
        return info[country]?.0
    }

    public static func placeholder(_ country: String) -> String? {
        return self.info[country]?.1
    }

    public static func displayName(_ iban: String) -> String {
        let country = String(iban.prefix(2))
        let prefix = String(iban.prefix(4))
        let suffix = String(iban.suffix(2))

        guard let placeholder = IBAN.placeholder(country) else {
            let len = max(iban.count - 6, 0)
            let dots = String(repeating: "•", count: len)
            return prefix + " " + dots + " " + suffix
        }

        let start = placeholder.index(placeholder.startIndex, offsetBy: 2)
        let end = placeholder.index(placeholder.endIndex, offsetBy: -2)

        return prefix + String(placeholder[start..<end]) + suffix
    }
       
    public static func prettyPrint(_ iban: String) -> String {
        let iban = iban.replacingOccurrences(of: " ", with: "")
        let country = String(iban.prefix(2))
        
        guard let placeholder = IBAN.placeholder(country), placeholder.replacingOccurrences(of: " ", with: "").count == iban.count - 2 else {
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
    
    public static func numberFormatter(country: String) -> NumberFormatter? {
        guard let placeholder = placeholder(country) else {
            return nil
        }
        var result = ""
        for char in String(placeholder) {
            if char == " " {
                result.append(" ")
            } else {
                result.append("#")
            }
        }
        let formatter = NumberFormatter()
        
        formatter.positiveFormat = result
        return formatter
    }
    
    // see https://en.wikipedia.org/wiki/International_Bank_Account_Number#Modulo_operation_on_IBAN
    public static func verify(iban: String) -> Bool {
        var rawBytes = Array(iban.utf8)
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

public class IBANFormatter: Formatter {
    public var placeholder: String {
        didSet {
            print("IBAN placeholder: \(placeholder)")
        }
    }
    let characterSet = CharacterSet(charactersIn: "0123456789 ")

    public init(country: String = "DE") {
        if let placeholder = IBAN.placeholder(country) {
            self.placeholder = placeholder
        } else {
            self.placeholder = IBAN.placeholder("DE")!
        }
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func isValid(_ value: String) -> Bool {
        guard let invalidRange = value.rangeOfCharacter(from: characterSet.inverted) else {
            return true
        }
        return invalidRange.isEmpty
    }

    private func convert(string: String) -> String {
        let iban = string.replacingOccurrences(of: " ", with: "")
        let inLength = iban.count
        var offset: Int = 0
        var result = ""

        for char in String(placeholder[placeholder.startIndex...]) {
            guard offset < inLength else {
                continue
            }
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

    public override func string(for obj: Any?) -> String? {
        guard let string = obj as? String else {
            return nil
        }
        return convert(string: string)
    }

    public override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
                                        for string: String,
                                        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let hexValue = convert(string: string)

        obj?.pointee = hexValue as AnyObject
        return true
    }

    public override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        guard partialString.count <= placeholder.count else { return false }

        return isValid(partialString)
    }
}
