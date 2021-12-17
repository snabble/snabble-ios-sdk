//
//  CheckoutProcess+Check.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

extension CheckoutProcess {
    public struct Check: Decodable {
        public let id: String

        public let state: State
        public let type: `Type`
        public let method: Method?

        public enum State: String, Codable, UnknownCaseRepresentable {
            case unknown

            case pending
            case postponed
            case successful
            case failed

            public static let unknownCase = Self.unknown
        }

        public enum `Type`: String, Codable, UnknownCaseRepresentable {
            case unknown

            case minAge = "min_age"
            case supervisorApproval = "supervisor_approval"
            case verifyDebitCard = "verify_debit_card"

            public static let unknownCase = Self.unknown
        }

        public enum Method: String, Decodable, UnknownCaseRepresentable {
            case unknown

            case none
            case control
            case partialRescan
            case rescan
            case gatekeeper

            public static let unknownCase = Self.unknown
        }
    }

    // are there any `failed` checks?
    public var failedChecks: Bool {
        checks.contains { $0.state == .failed }
    }

    // are there any `pending` checks?
    public var pendingChecks: Bool {
        checks.contains { $0.state == .pending }
    }

    // are all checks `successful`?
    public var allChecksSuccessful: Bool {
        checks.allSatisfy { $0.state == .successful }
    }

    public var supervisorApprovalDenied: Bool {
        routingTarget == .supervisor && failedChecks
    }

    public var supervisorApprovalGranted: Bool {
        routingTarget == .supervisor && allChecksSuccessful
    }
}
