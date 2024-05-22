//
//  Authenticator.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-19.
//

import Foundation
import Dispatch
import Combine
import SnabbleLogger

protocol AuthenticatorDelegate: AnyObject {
    func authenticator(_ authenticator: Authenticator, didUpdateCredentials credentials: Credentials?)
}

public class Authenticator {
    public let urlSession: URLSession
    public let apiKey: String

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

    private let queue: DispatchQueue = .init(label: "io.snabble.pay.authenticator.\(UUID().uuidString)")

    private var refreshPublisher: AnyPublisher<Token, APIError>?

    init(apiKey: String, credentials: Credentials?, urlSession: URLSession) {
        self.urlSession = urlSession
        self.apiKey = apiKey
        self.credentials = credentials
    }

    func invalidateToken() {
        token = nil
    }

    private func validateCredentials(onEnvironment environment: Environment = .production) -> AnyPublisher<Credentials, APIError> {
        // scenario 1: app instance is registered
        if let credentials = self.credentials {
            Logger.shared.debug("Uses Credentials: \(credentials)")
            return Just(credentials)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }

        // scenario 2: we have to register the app instance
        let endpoint = Endpoints.Register.post(
            apiKeyValue: apiKey,
            onEnvironment: environment
        )
        let publisher = urlSession.publisher(for: endpoint)
            .handleEvents(receiveOutput: { [weak self] credentials in
                self?.credentials = credentials
            }, receiveCompletion: { _ in })
            .eraseToAnyPublisher()
        return publisher
    }

    func validToken(
        forceRefresh: Bool = false,
        onEnvironment environment: Environment = .production
    ) -> AnyPublisher<Token, APIError> {
        return queue.sync { [weak self] in
            guard let self = self else {
                Logger.shared.error("Unexpected: Authenticator is missing")
                return Fail(
                    outputType: Token.self,
                    failure: APIError.unexpected(Error.missingAuthenticator)
                ).eraseToAnyPublisher()
            }

            // scenario 1: we're already loading a new token
            if let publisher = self.refreshPublisher {
                return publisher
            }

            // scenario 2: we already have a valid token and don't want to force a refresh
            if let token = self.token, token.isValid(), !forceRefresh {
                Logger.shared.debug("Uses Token: \(token)")
                return Just(token)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }

            // scenario 3: we need a new token
            Logger.shared.debug("Token is refreshed")
            let publisher = self.validateCredentials(onEnvironment: environment)
                .map { credentials -> Endpoint<Token> in
                    return Endpoints.Token.get(
                        withCredentials: credentials,
                        onEnvironment: environment
                    )
                }
                .tryMap { tokenEndpoint -> (URLSession, Endpoint<Token>) in
                    return (self.urlSession, tokenEndpoint)
                }
                .mapError { $0 as? APIError ?? .unexpected($0) }
                .flatMap { urlSession, endpoint in
                    return urlSession.publisher(for: endpoint)
                }
                .share()
                .handleEvents(receiveOutput: { token in
                    self.token = token
                }, receiveCompletion: { _ in
                    self.queue.sync {
                        self.refreshPublisher = nil
                    }
                })
                .eraseToAnyPublisher()

            self.refreshPublisher = publisher
            return publisher
        }
    }
}
