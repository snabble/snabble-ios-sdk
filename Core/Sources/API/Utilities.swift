//
//  Utilities.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// MARK: - string-based enums

/// for RawRepresentable enums, define a `unknownCase` fallback and a non-failable initializer
public protocol UnknownCaseRepresentable: RawRepresentable, CaseIterable where RawValue: Equatable {
    static var unknownCase: Self { get }
}

extension UnknownCaseRepresentable {
    public init(rawValue: RawValue) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? Self.unknownCase
    }
}

/// helper struct for JSON decoding
struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try? container.decode(T.self)
    }
}

// MARK: - Logging
public enum Log {
    public static func info(_ str: String) {
        NSLog("[snabble] INFO: %@", str)
    }

    public static func debug(_ str: String) {
        NSLog("[snabble] DEBUG: %@", str)
    }

    public static func warn(_ str: String) {
        NSLog("[snabble] WARN: %@", str)
    }

    public static func error(_ str: String) {
        NSLog("[snabble] ERROR: %@", str)
    }
}

// MARK: - ISO8601/RFC3339 date formatting
extension Formatter {
    nonisolated(unsafe) static let iso8601withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

// provide a date decoding strategy that can actually parse ISO8601 dates, including those with fractional seconds
extension JSONDecoder.DateDecodingStrategy {
    public static let customISO8601 = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = Formatter.iso8601withFractionalSeconds.date(from: string) ?? Formatter.iso8601.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}
