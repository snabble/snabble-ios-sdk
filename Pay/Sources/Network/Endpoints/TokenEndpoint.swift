//
//  TokenEndpoint.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import SnabbleNetwork

extension Endpoints {
    enum Token {
        static func get(
            withCredentials credentials: Credentials,
            scope: SnabblePayNetwork.Token.Scope = .all,
            onEnvironment environment: Environment = .production
        ) -> Endpoint<SnabblePayNetwork.Token> {
            var urlComponents = URLComponents()
            urlComponents.queryItems = [
                .init(name: "grant_type", value: "client_credentials"),
                .init(name: "client_id", value: credentials.identifier),
                .init(name: "client_secret", value: credentials.secret),
                .init(name: "scope", value: scope.rawValue)
            ]
            return Endpoint(
                path: "/apps/token",
                method: .post(urlComponents.query?.data(using: .utf8)),
                parse: { try Endpoints.jsonDecoder.decode(SnabblePayNetwork.Token.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL, additionalHeaderFields: ["Content-Type": "application/x-www-form-urlencoded"])
        }
    }
}
