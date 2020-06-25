//
//  Utilities.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

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
enum Log {
    static func info(_ str: String) {
        NSLog("[snabble] INFO: %@", str)
    }

    static func debug(_ str: String) {
        NSLog("[snabble] DEBUG: %@", str)
    }

    static func warn(_ str: String) {
        NSLog("[snabble] WARN: %@", str)
    }

    static func error(_ str: String) {
        NSLog("[snabble] ERROR: %@", str)
    }
}

let iso8601Formatter: ISO8601DateFormatter = {
    let fmt = ISO8601DateFormatter()
    fmt.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
    fmt.formatOptions = .withInternetDateTime
    if #available(iOS 11.2, *) {
        fmt.formatOptions.insert(.withFractionalSeconds)
    }
    return fmt
}()
