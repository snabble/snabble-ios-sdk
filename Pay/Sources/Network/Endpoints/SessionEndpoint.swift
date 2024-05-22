//
//  SessionEndpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-19.
//

import Foundation

public typealias ModelSession = Session

extension Endpoints {
    public enum Session {
        public static func post(withAccountId accountId: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession> {
            let jsonObject = ["accountId": accountId]
            return .init(
                path: "/apps/sessions",
                // swiftlint:disable:next force_try
                method: .post(try! JSONSerialization.data(withJSONObject: jsonObject)),
                environment: environment
            )
        }

        public static func get(onEnvironment environment: Environment = .production) -> Endpoint<[ModelSession]> {
            return .init(path: "/apps/sessions", method: .get(nil), environment: environment)
        }

        public static func get(id: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession> {
            return .init(path: "/apps/sessions/\(id)", method: .get(nil), environment: environment)
        }

        public static func delete(id: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession> {
            return .init(path: "/apps/sessions/\(id)", method: .delete, environment: environment)
        }
    }
}

extension Endpoints.Session {
    public enum Token {
        public static func post(sessionId: String, onEnvironment environment: Environment = .production) -> Endpoint<ModelSession.Token> {
            return .init(path: "/apps/sessions/\(sessionId)/token", method: .post(nil), environment: environment)
        }
    }
}
