//
//  Authenticator.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-19.
//

import Foundation

@MainActor
protocol AuthenticatorDelegate: AnyObject {
    func authenticator(_ authenticator: Authenticator, appUserForConfiguration configuration: Configuration) -> AppUser?
    func authenticator(_ authenticator: Authenticator, appUserUpdated appUser: AppUser)
    func authenticator(_ authenticator: Authenticator, projectIdForConfiguration configuration: Configuration) -> String?
}

@MainActor
final class Authenticator {
    let urlSession: URLSession
    weak var delegate: AuthenticatorDelegate?

    enum Error: Swift.Error {
        case missingAuthenticator
        case missingProject
    }

    private(set) var token: Token?
    private var refreshTask: Task<Token, Swift.Error>?

    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    func updateAppUser(_ appUser: AppUser) {
        invalidateToken()
        delegate?.authenticator(self, appUserUpdated: appUser)
    }

    func invalidateToken() {
        token = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    func validToken(withConfiguration configuration: Configuration, forceRefresh: Bool = false) async throws -> Token {
        if !forceRefresh, let task = refreshTask {
            return try await task.value
        }
        if !forceRefresh, let token, token.isValid() {
            return token
        }
        if forceRefresh {
            refreshTask?.cancel()
            refreshTask = nil
        }
        let task = Task { [weak self] in
            guard let self else { throw Error.missingAuthenticator }
            return try await self.fetchToken(configuration: configuration)
        }
        refreshTask = task
        do {
            let fetchedToken = try await task.value
            token = fetchedToken
            refreshTask = nil
            return fetchedToken
        } catch {
            refreshTask = nil
            throw error
        }
    }

    private func fetchToken(configuration: Configuration) async throws -> Token {
        let appUser = try await validateAppUser(withConfiguration: configuration)
        guard let projectId = delegate?.authenticator(self, projectIdForConfiguration: configuration) ?? configuration.projectId else {
            throw Error.missingProject
        }
        var endpoint = Endpoints.Token.get(
            appId: configuration.appId,
            appSecret: configuration.appSecret,
            appUser: appUser,
            projectId: projectId
        )
        endpoint.domain = configuration.domain
        return try await urlSession.data(for: endpoint)
    }

    private func validateAppUser(withConfiguration configuration: Configuration) async throws -> AppUser {
        if let appUser = delegate?.authenticator(self, appUserForConfiguration: configuration) {
            return appUser
        }
        var endpoint = Endpoints.AppUser.post(appId: configuration.appId, appSecret: configuration.appSecret)
        endpoint.domain = configuration.domain
        let response: UsersResponse = try await urlSession.data(for: endpoint)
        delegate?.authenticator(self, appUserUpdated: response.appUser)
        return response.appUser
    }
}
