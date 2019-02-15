//
//  Utilities.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

/// for RawRepresentable enums, define a `unknownCase` fallback and a non-failable initializer
protocol UnknownCaseRepresentable: RawRepresentable, CaseIterable where RawValue: Equatable {
    static var unknownCase: Self { get }
}

extension UnknownCaseRepresentable {
    public init(rawValue: RawValue) {
        let value = Self.allCases.first(where: { $0.rawValue == rawValue })
        self = value ?? Self.unknownCase
    }
}
