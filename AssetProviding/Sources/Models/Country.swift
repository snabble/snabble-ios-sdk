//
//  Country.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-03-14.
//

import Foundation

public struct Country: Decodable, Equatable {
    nonisolated(unsafe) public static var all: [Country] = loadJSON("countries")
    nonisolated(unsafe) public static var germany: Country = Country(code: "DE", numeric: "276")
    
    public let code: String
    public let states: [State]?
    public let numeric: String?
    
    init(code: String, states: [State]? = nil, numeric: String? = nil) {
        self.code = code
        self.states = states
        self.numeric = numeric
    }
    
    public struct State: Decodable, Equatable {
        public let code: String
        public let name: String

        public var label: String {
            name
        }
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

extension Country.State: Identifiable {
    public var id: String {
        code
    }
}

extension Country: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Country.State: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Country {
    public var name: String {
        Locale.current.localizedString(forRegionCode: code) ?? "n/a"
    }
}

extension Array where Element == Country {    
    public func country(forCode code: String) -> Element? {
        first(where: { $0.code.lowercased() == code.lowercased()})
    }
}

extension Array where Element == Country.State {
    public func state(forCode code: String) -> Element? {
        first(where: { $0.code.lowercased() == code.lowercased()})
    }
}

extension String {
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
