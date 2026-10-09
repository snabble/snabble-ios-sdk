//
//  SessionEndpoint.swift
//
//
//  Created by Andreas Osberghaus on 2023-01-19.
//

import Foundation
import SnabbleNetwork

public typealias ModelSession = Session

extension Endpoints {
    public enum Session {
        public static func post(withAccountId accountId: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession> {
            let jsonObject = ["accountId": accountId]
            return Endpoint(
                path: "/apps/sessions",
                // swiftlint:disable:next force_try
                method: .post(try! JSONSerialization.data(withJSONObject: jsonObject)),
                parse: { try Endpoints.jsonDecoder.decode(ModelSession.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func get(onEnvironment environment: Environment = .production) -> Endpoint<[ModelSession]> {
            Endpoint(
                path: "/apps/sessions",
                method: .get(nil),
                parse: { try Endpoints.jsonDecoder.decode([ModelSession].self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func get(id: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession> {
            Endpoint(
                path: "/apps/sessions/\(id)",
                method: .get(nil),
                parse: { try Endpoints.jsonDecoder.decode(ModelSession.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func delete(id: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession> {
            Endpoint(
                path: "/apps/sessions/\(id)",
                method: .delete,
                parse: { try Endpoints.jsonDecoder.decode(ModelSession.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }
    }
}

extension Endpoints.Session {
    public enum Token {
        public static func post(sessionId: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession.Token> {
            Endpoint(
                path: "/apps/sessions/\(sessionId)/token",
                method: .post(nil),
                parse: { try Endpoints.jsonDecoder.decode(ModelSession.Token.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }
    }
}
