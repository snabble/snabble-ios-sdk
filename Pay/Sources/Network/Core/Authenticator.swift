//
//  Authenticator.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-19.
//

import Foundation
import SnabbleLogger

@MainActor
protocol AuthenticatorDelegate: AnyObject {
    func authenticator(_ authenticator: Authenticator, didUpdateCredentials credentials: Credentials?)
}

@MainActor
final class Authenticator {
    let urlSession: URLSession
    let apiKey: String

    weak var delegate: AuthenticatorDelegate?

    private(set) var token: Token? {
        didSet {
            Logger.shared.debug("Update Token: \(String(describing: token))")
        }
    }
    private(set) var credentials: Credentials? {
        didSet {
            Logger.shared.debug("Update Credentials: \(String(describing: credentials))")
            delegate?.authenticator(self, didUpdateCredentials: credentials)
        }
    }

    enum Error: Swift.Error {
        case missingAuthenticator
    }

    private var refreshTask: Task<Token, Swift.Error>?

    init(apiKey: String, credentials: Credentials?, urlSession: URLSession) {
        self.urlSession = urlSession
        self.apiKey = apiKey
        self.credentials = credentials
    }

    func invalidateToken() {
        token = nil
    }

    private func validateCredentials(onEnvironment environment: Environment = .production) async throws -> Credentials {
        // scenario 1: app instance is registered
        if let credentials {
            Logger.shared.debug("Uses Credentials: \(credentials)")
            return credentials
        }

        // scenario 2: we have to register the app instance
        let endpoint = Endpoints.Register.post(apiKeyValue: apiKey, onEnvironment: environment)
        let credentials = try await urlSession.data(for: endpoint)
        self.credentials = credentials
        return credentials
    }

    func validToken(
        forceRefresh: Bool = false,
        onEnvironment environment: Environment = .production
    ) async throws -> Token {
        // scenario 1: we're already loading a new token
        if let refreshTask {
            return try await refreshTask.value
        }

        // scenario 2: we already have a valid token and don't want to force a refresh
        if !forceRefresh, let token, token.isValid() {
            Logger.shared.debug("Uses Token: \(token)")
            return token
        }

        // scenario 3: we need a new token
        Logger.shared.debug("Token is refreshed")
        let task = Task<Token, Swift.Error> { [weak self] in
            guard let self else {
                Logger.shared.error("Unexpected: Authenticator is missing")
                throw Error.missingAuthenticator
            }
            let credentials = try await self.validateCredentials(onEnvironment: environment)
            let endpoint = Endpoints.Token.get(withCredentials: credentials, onEnvironment: environment)
            return try await self.urlSession.data(for: endpoint)
        }
        refreshTask = task

        defer { refreshTask = nil }

        let token = try await task.value
        self.token = token
        return token
    }
}
