//
//  Identifier.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 06.01.21.
//

import Foundation

public protocol Identifiable {
    associatedtype RawIdentifier: Codable & Hashable = String
    var id: Identifier<Self> { get }
}

public struct Identifier<Value: Identifiable>: RawRepresentable {
    public let rawValue: Value.RawIdentifier

    public init(rawValue: Value.RawIdentifier) {
        self.rawValue = rawValue
    }
}

// MARK: - Codable

extension Identifier: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Value.RawIdentifier.self)
        self.init(rawValue: rawValue)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - ExpressibleByStringLiteral

extension Identifier: ExpressibleByUnicodeScalarLiteral where Value.RawIdentifier == String {
    public init(unicodeScalarLiteral value: UnicodeScalar) {
        rawValue = String(describing: Character(value))
    }
}

extension Identifier: ExpressibleByExtendedGraphemeClusterLiteral where Value.RawIdentifier == String {
    public init(extendedGraphemeClusterLiteral value: Character) {
        rawValue = String(describing: value)
    }
}

extension Identifier: ExpressibleByStringLiteral where Value.RawIdentifier == String {
    public init(stringLiteral value: Value.RawIdentifier) {
        rawValue = value
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Identifier: ExpressibleByIntegerLiteral where Value.RawIdentifier == Int {
    public init(integerLiteral value: Value.RawIdentifier) {
        rawValue = value
    }
}

// MARK: - Hashable

extension Identifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: - CustomStringConvertible

extension Identifier: CustomStringConvertible {
    public var description: String {
        String(describing: rawValue)
    }
}
