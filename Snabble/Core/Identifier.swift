//
//  Identifier.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 06.01.21.
//

import Foundation

public protocol AnyIdentifiable {
    var id: Identifier<Self> { get }
}

public struct Identifier<Value: AnyIdentifiable> {
    public typealias RawIdentifier = String

    public let rawValue: RawIdentifier

    public init(rawValue: RawIdentifier) {
        self.rawValue = rawValue
    }
}

// MARK: - Codable

extension Identifier: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawIdentifier.self)
        self.init(rawValue: rawValue)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Hashable

extension Identifier: Hashable {
    public static func == (lhs: Identifier<Value>, rhs: Identifier<Value>) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: - CustomStringConvertible

extension Identifier: CustomStringConvertible {
    public var description: String {
        "identifier: \(rawValue)"
    }
}
