//
//  NetworkManager.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-19.
//

import Foundation
import SnabbleNetwork

@MainActor
public protocol NetworkManagerDelegate: AnyObject {
    func networkManager(_ networkManager: NetworkManager, didUpdateCredentials credentials: Credentials?)
}

@MainActor
public final class NetworkManager {
    public let urlSession: URLSession

    public weak var delegate: NetworkManagerDelegate?

    let authenticator: Authenticator

    public init(apiKey: String, credentials: Credentials?, urlSession: URLSession) {
        self.urlSession = urlSession

        self.authenticator = Authenticator(
            apiKey: apiKey,
            credentials: credentials,
            urlSession: urlSession
        )
        self.authenticator.delegate = self
    }

    public var apiKey: String {
        authenticator.apiKey
    }

    public func publisher<Response>(for endpoint: Endpoint<Response>, onEnvironment environment: Environment) async throws -> Response {
        let token = try await authenticator.validToken(onEnvironment: environment)
        let authorizedEndpoint = endpoint.with(additionalHeaderFields: [
            "Authorization": "\(token.type.rawValue) \(token.value)"
        ])
        do {
            return try await urlSession.data(for: authorizedEndpoint)
        } catch let error as PayHTTPError {
            guard case .validationError(let httpStatusCode, _) = error, httpStatusCode == .unauthorized else {
                throw error
            }
            authenticator.invalidateToken()
            let refreshedToken = try await authenticator.validToken(forceRefresh: true, onEnvironment: environment)
            let retriedEndpoint = endpoint.with(additionalHeaderFields: [
                "Authorization": "\(refreshedToken.type.rawValue) \(refreshedToken.value)"
            ])
            return try await urlSession.data(for: retriedEndpoint)
        }
    }
}

extension NetworkManager: AuthenticatorDelegate {
    func authenticator(_ authenticator: Authenticator, didUpdateCredentials credentials: Credentials?) {
        delegate?.networkManager(self, didUpdateCredentials: credentials)
    }
}
