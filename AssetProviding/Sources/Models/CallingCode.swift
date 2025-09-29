//
//  File.swift
//  
//
//  Created by Uwe Tilemann on 07.08.24.
//

import Foundation

public struct CallingCode: Decodable, Identifiable {
    nonisolated(unsafe) public static var all: [CallingCode] = loadJSON("calling-codes")
    nonisolated(unsafe) public static var germany: CallingCode = CallingCode(identifier: "DE", code: 49)

    public let id: String
    public let code: UInt
    
    enum CodingKeys: String, CodingKey {
        case identifier = "code"
        case code = "callingCode"
    }

    public init(identifier: String, code: UInt) {
        self.id = identifier
        self.code = code
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .identifier)
        self.code = try container.decode(UInt.self, forKey: .code)
    }

    public var flagSymbol: String? {
        id.flagSymbol
    }
}

extension CallingCode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension CallingCode {
    var name: String {
        Locale.current.localizedString(forRegionCode: id) ?? "n/a"
    }
}

public extension Array where Element == CallingCode {
    var ids: [String] {
        compactMap({ $0.id })
    }

    func callingCode(forId id: String) -> Element? {
        first(where: { $0.id.lowercased() == id.lowercased()})
    }
    
    func callingCode(forCode code: UInt) -> Element? {
        first(where: { $0.code == code })
    }
}
