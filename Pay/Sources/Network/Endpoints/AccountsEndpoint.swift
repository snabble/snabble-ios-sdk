//
//  AccountsEndpoint.swift
//
//
//  Created by Andreas Osberghaus on 2023-01-25.
//

import Foundation
import SnabbleNetwork

extension Endpoints {
    public enum Accounts {
        public static func check(appUri: URL, city: String, countryCode: String, onEnvironment environment: Environment = .production) -> Endpoint<Account.Check> {
            Endpoint(
                path: "/apps/accounts/check",
                method: .get(
                  [
                      .init(name: "appUri", value: appUri.absoluteString),
                      .init(name: "countryCode", value: countryCode),
                      .init(name: "city", value: city)
                  ]
                ),
                parse: { try Endpoints.jsonDecoder.decode(Account.Check.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func get(onEnvironment environment: Environment = .production) -> Endpoint<[Account]> {
            Endpoint(path: "/apps/accounts", method: .get(nil), parse: { try Endpoints.jsonDecoder.decode([Account].self, from: $0) })
                .with(baseURLOverride: environment.baseURL)
        }

        public static func get(id: String, onEnvironment environment: Environment = .production) -> Endpoint<Account> {
            Endpoint(path: "/apps/accounts/\(id)", method: .get(nil), parse: { try Endpoints.jsonDecoder.decode(Account.self, from: $0) })
                .with(baseURLOverride: environment.baseURL)
        }

        public static func delete(id: String, onEnvironment environment: Environment = .production) -> Endpoint<Account> {
            Endpoint(path: "/apps/accounts/\(id)", method: .delete, parse: { try Endpoints.jsonDecoder.decode(Account.self, from: $0) })
                .with(baseURLOverride: environment.baseURL)
        }
    }
}
