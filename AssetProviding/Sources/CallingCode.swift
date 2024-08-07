//
//  File.swift
//  
//
//  Created by Uwe Tilemann on 07.08.24.
//

import Foundation

public struct CallingCode: Decodable {
    public static var all: [CallingCode] = loadJSON("calling-codes")
    public static var germany: CallingCode = CallingCode(code: "DE", callingCode: 49)

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

extension CallingCode: Identifiable {
    public var id: String {
        code
    }
}

extension CallingCode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CallingCode {
    var name: String {
        Locale.current.localizedString(forRegionCode: code) ?? "n/a"
    }
}

public extension Array where Element == CallingCode {
    var callingCodes: [String] {
        compactMap({ $0.code })
    }

    func callingCode(forCode code: String) -> Element? {
        first(where: { $0.code.lowercased() == code.lowercased()})
    }
}
