//
//  NetworkManager.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-19.
//

import Foundation
import Observation

@MainActor
public protocol NetworkManagerDelegate: AnyObject {
    func networkManager(_ networkManager: NetworkManager, appUserForConfiguration configuration: Configuration) -> AppUser?
    func networkManager(_ networkManager: NetworkManager, appUserUpdated appUser: AppUser)
    func networkManager(_ networkManager: NetworkManager, projectIdForConfiguration configuration: Configuration) -> String?
}

@Observable
@MainActor
public final class NetworkManager {
    public let configuration: Configuration

    @ObservationIgnored private let authenticator: Authenticator
    @ObservationIgnored public weak var delegate: (any NetworkManagerDelegate)?

    public init(configuration: Configuration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.authenticator = Authenticator(urlSession: urlSession)
        self.authenticator.delegate = self
    }

    public var urlSession: URLSession {
        authenticator.urlSession
    }

    public func publisher<Response: Sendable>(for endpoint: Endpoint<Response>) async throws -> Response {
        do {
            return try await perform(endpoint)
        } catch let HTTPError.invalid(response, _) where response.httpStatusCode == .unauthorized || response.httpStatusCode == .forbidden {
            authenticator.invalidateToken()
            return try await perform(endpoint)
        }
    }

    private func perform<Response: Sendable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        let token = try await authenticator.validToken(withConfiguration: configuration)
        var modifiedEndpoint = endpoint
        modifiedEndpoint.domain = configuration.domain
        modifiedEndpoint.token = token
        let response = try await authenticator.urlSession.data(for: modifiedEndpoint)
        if let appUser = response as? AppUser {
            authenticator.updateAppUser(appUser)
        }
        return response
    }
}

extension NetworkManager: AuthenticatorDelegate {
    func authenticator(_ authenticator: Authenticator, appUserUpdated appUser: AppUser) {
        delegate?.networkManager(self, appUserUpdated: appUser)
    }

    func authenticator(_ authenticator: Authenticator, appUserForConfiguration configuration: Configuration) -> AppUser? {
        delegate?.networkManager(self, appUserForConfiguration: configuration)
    }

    func authenticator(_ authenticator: Authenticator, projectIdForConfiguration configuration: Configuration) -> String? {
        delegate?.networkManager(self, projectIdForConfiguration: configuration)
    }
}
