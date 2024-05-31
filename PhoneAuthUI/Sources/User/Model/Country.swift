//
//  Country.swift
//  teo
//
//  Created by Andreas Osberghaus on 2024-03-14.
//

import Foundation

struct Country: Decodable, Equatable {
    public static var all: [Country] = loadJSON("countries")
    public static var germany: Country = Country(code: "DE")
    
    let code: String
    let states: [State]?
    
    init(code: String, states: [State]? = nil) {
        self.code = code
        self.states = states
    }
    
    struct State: Decodable, Equatable {
        let code: String
        let label: String
    }
    
    var flagSymbol: String? {
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
    var name: String {
        Locale.current.localizedString(forRegionCode: code) ?? "n/a"
    }
}

extension Array where Element == Country {    
    func country(forCode code: String) -> Element? {
        first(where: { $0.code.lowercased() == code.lowercased()})
    }
}

extension Array where Element == Country.State {
    func state(forCode code: String) -> Element? {
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
