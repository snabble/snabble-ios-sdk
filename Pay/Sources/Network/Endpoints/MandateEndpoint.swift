//
//  MandateEndpoint.swift
//
//
//  Created by Andreas Osberghaus on 2023-01-23.
//

import Foundation
import SnabbleNetwork

extension Endpoints.Accounts {
    public enum Mandate {
        public static func post(forAccountId accountId: String, onEnvironment environment: Environment = .production) -> Endpoint<Account.Mandate> {
            Endpoint(
                path: "/apps/accounts/\(accountId)/mandate",
                method: .post(nil),
                parse: { try Endpoints.jsonDecoder.decode(Account.Mandate.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func get(forAccountId accountId: String, onEnvironment environment: Environment = .production) -> Endpoint<Account.Mandate> {
            Endpoint(
                path: "/apps/accounts/\(accountId)/mandate",
                method: .get(nil),
                parse: { try Endpoints.jsonDecoder.decode(Account.Mandate.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func accept(mandateId: String, forAccountId accountId: String, onEnvironment environment: Environment = .production) -> Endpoint<Account.Mandate> {
            Endpoint(
                path: "/apps/accounts/\(accountId)/mandate",
                method: .patch(data(for: .accept, withMandateId: mandateId)),
                parse: { try Endpoints.jsonDecoder.decode(Account.Mandate.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func decline(mandateId: String, forAccountId accountId: String, onEnvironment environment: Environment = .production) -> Endpoint<Account.Mandate> {
            Endpoint(
                path: "/apps/accounts/\(accountId)/mandate",
                method: .patch(data(for: .decline, withMandateId: mandateId)),
                parse: { try Endpoints.jsonDecoder.decode(Account.Mandate.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        private enum Action: String {
            case accept = "ACCEPTED"
            case decline = "DECLINED"
        }

        // swiftlint:disable force_try
        private static func data(for action: Action, withMandateId mandateId: String) -> Data {
            let jsonObject = [
                "id": mandateId,
                "state": action.rawValue
            ]
            return try! JSONSerialization.data(withJSONObject: jsonObject)
        }
        // swiftlint:enable force_try
    }
}
