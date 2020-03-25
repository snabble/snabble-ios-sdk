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

enum IBAN {
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

    static func length(_ country: String) -> Int? {
        return info[country]?.0
    }

    static func placeholder(_ country: String) -> String? {
        return self.info[country]?.1
    }

    static func displayName(_ iban: String) -> String {
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
}
