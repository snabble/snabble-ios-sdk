//
//  Identifier.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 06.01.21.
//

import Foundation

public protocol Identifiable {
    var id: Identifier<Self> { get }
}

public struct Identifier<Value: Snabble.Identifiable>: RawRepresentable {
    public typealias RawIdentifier = String

    public let rawValue: RawIdentifier

    public init(rawValue: RawIdentifier) {
        self.rawValue = rawValue
    }

    public var isEmpty: Bool {
        rawValue.isEmpty
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

// MARK: - ExpressibleByStringLiteral

extension Identifier: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
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
        rawValue
    }
}
