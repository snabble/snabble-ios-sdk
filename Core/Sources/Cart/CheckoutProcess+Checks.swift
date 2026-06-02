//
//  CheckoutProcess+Check.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

extension CheckoutProcess {
    public struct Check: Decodable, Sendable {
        public let id: String

        public let state: State

        public enum State: String, Codable, UnknownCaseRepresentable, Sendable {
            case pending
            case postponed
            case successful
            case failed

            public static let unknownCase = Self.failed
        }
    }

    // are there any `failed` checks?
    public var hasFailedChecks: Bool {
        checks.contains { $0.state == .failed }
    }

    // are there any `pending` checks?
    public var hasPendingChecks: Bool {
        checks.contains { $0.state == .pending }
    }

    // are all checks `successful`?
    public var allChecksSuccessful: Bool {
        checks.allSatisfy { $0.state == .successful }
    }
}
