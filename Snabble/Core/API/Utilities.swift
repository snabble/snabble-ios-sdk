//
//  Utilities.swift
//
//  Copyright © 2019 snabble. All rights reserved.
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

/// run `closure` synchronized using `lock`
func synchronized<T>(_ lock: Any, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}

let iso8601Formatter: ISO8601DateFormatter = {
    let fmt = ISO8601DateFormatter()
    fmt.timeZone = TimeZone.current
    fmt.formatOptions = .withInternetDateTime
    if #available(iOS 11.2, *) {
        fmt.formatOptions.insert(.withFractionalSeconds)
    }
    return fmt
}()
