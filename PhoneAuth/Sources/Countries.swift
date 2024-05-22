//
//  Countries.swift
//  Country Picker
//
//  Created by Uwe Tilemann on 07.03.24.
//

import Foundation

public struct Country: Decodable {
    public static var all: [Country] = loadJSON("Countries")
    public static var germany: Country = Country(code: "DE", callingCode: 49)

    public let code: String
    public let callingCode: UInt

    public init(code: String, callingCode: UInt) {
        self.code = code
        self.callingCode = callingCode
    }

    public var flagSymbol: String? {
        code.flagSymbol
    }
}

extension Country: Identifiable {
    public var id: String {
        code
    }
}

extension Country: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension Array where Element == Country {
    var countryCodes: [String] {
        compactMap({ $0.code })
    }

    func country(forCode code: String) -> Element? {
        first(where: { $0.code.lowercased() == code.lowercased()})
    }
}

private extension String {
    var flagSymbol: String? {
        let base: UInt32 = 127397
        var result = ""
        for char in self.unicodeScalars {
            if let flagScalar = UnicodeScalar(base + char.value) {
                result.unicodeScalars.append(flagScalar)
            }
        }
        return result.isEmpty ? nil : String(result)
    }
}
