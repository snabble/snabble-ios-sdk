//
//  TokenRegistry.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import SwiftOTP
import SnabbleNetwork

#if canImport(UIKit)
import UIKit
#endif

// backend response
private struct AppUserResponse: Decodable {
    let appUser: AppUser
    let token: TokenResponse

    struct AppUser: Decodable {
        let id: String
        let secret: String
    }
}

private struct TokenResponse: Decodable {
    let id: String
    let token: String
    let issuedAt: Int64
    let expiresAt: Int64
}

// stored in our token registry
private struct TokenData {
    let jwt: String
    let expires: Date
    let refresh: Date
    let projectId: Identifier<Project>

    init(_ response: TokenResponse, _ projectId: Identifier<Project>) {
        let expiresAt = Date(timeIntervalSince1970: TimeInterval(response.expiresAt))

        // make sure expires is at least 60s from now
        let minDate = Date(timeIntervalSinceNow: 60)
        let expires = max(minDate, expiresAt)
        let refreshIn = (expires.timeIntervalSinceReferenceDate - Date.timeIntervalSinceReferenceDate) / 2

        self.expires = expires
        self.refresh = Date(timeIntervalSinceNow: refreshIn)

        self.projectId = projectId
        self.jwt = response.token
    }
}

public final class TokenRegistry: @unchecked Sendable {
    private let appId: String
    private let secret: String

    private var verboseToken = false

    private var projectTokens = [Identifier<Project>: TokenData]()
    private weak var refreshTimer: Timer?

    private typealias Handlers = [(String?) -> Void]
    private var pendingHandlers = [Identifier<Project>: Handlers ]()
    private var lock = ReadWriteLock()

    init(appId: String, secret: String) {
        self.appId = appId
        self.secret = secret

#if os(iOS)
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appEnteredForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appEnteredBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
#endif
    }

    /// get the JWT for `project`, retrieving a new one if no token existed or it was expired
    public func getToken(for project: Project, completion: @escaping @Sendable (String?) -> Void) {
        if let jwt = self.token(for: project.id) {
            return completion(jwt)
        }

        self.performTokenRetrieval(for: project.id, completion)
    }

    /// get the JWT for `project` if it exists and isn't expired.
    /// this method does NOT fetch new tokens
    public func getExistingToken(for project: Project) -> String? {
        token(for: project.id)
    }

    private func performTokenRetrieval(for projectId: Identifier<Project>, _ completion: @escaping @Sendable (String?) -> Void) {
        // no token in our registry, go fetch it
        let count: Int? = lock.writing {
            self.pendingHandlers[projectId, default: []].append(completion)
            return self.pendingHandlers[projectId]?.count
        }

        guard count == 1 else {
            return
        }

        self.retrieveToken(for: projectId) { tokenData in
            let handlers: Handlers? = self.lock.writing {
                if let tokenData = tokenData {
                    self.projectTokens[projectId] = tokenData
                    self.startRefreshTimer()
                    if Snabble.appUserData == nil {
                        Snabble.shared.fetchAppUserData(projectId)
                    }
                }

                return self.pendingHandlers.removeValue(forKey: projectId)
            }

            handlers?.forEach { handler in
                handler(tokenData?.jwt)
            }
        }
    }

    // raw, synchronous token access. externally only used by AppEvent.post() to avoid endless loops
    private func token(for projectId: Identifier<Project>) -> String? {
        lock.reading {
            if let token = self.projectTokens[projectId] {
                // we already have a token. return it if it's still valid
                let now = Date()
                if token.expires > now {
                    return token.jwt
                }
            }
            return nil
        }

    }

    // invalidate all tokens - called when the appUser changes
    public func invalidate() {
        self.refreshTimer?.invalidate()

        let activeIds: [Identifier<Project>] = lock.writing {
            let activeIds = Array(self.projectTokens.keys)
            self.projectTokens.removeAll()
            return activeIds
        }

        for projectId in activeIds {
            if let project = Snabble.shared.project(for: projectId) {
                self.getToken(for: project, completion: { _ in })
            }
        }
    }

    @objc private func appEnteredForeground(_ notification: Notification) {
        // Log.debug("app going to fg, start refresh")
        self.startRefreshTimer()
    }

    @objc private func appEnteredBackground(_ notification: Notification) {
        // Log.debug("app going to bg, stop refresh")
        self.refreshTimer?.invalidate()
    }

    private func startRefreshTimer() {
        let minRefresh = lock.reading {
            self.projectTokens.values.min(by: { $0.refresh < $1.refresh })
        }

        guard let earliest = minRefresh else {
            return
        }

        let now = Date.timeIntervalSinceReferenceDate
        let refreshIn = earliest.refresh.timeIntervalSinceReferenceDate - now

        if self.verboseToken { Log.debug("start refresh timer: run refresh in \(refreshIn)s") }
        DispatchQueue.main.async {
            self.refreshTimer?.invalidate()
            self.refreshTimer = Timer.scheduledTimer(withTimeInterval: max(1, refreshIn), repeats: false) { _ in
                self.refreshTokens()
            }
        }
    }

    private func refreshTokens() {
        let now = Date.timeIntervalSinceReferenceDate

        let group = DispatchGroup()

        let values = lock.reading { self.projectTokens.values }

        for tokenData in values where tokenData.refresh.timeIntervalSinceReferenceDate < now {
            group.enter()
            let projectId = tokenData.projectId
            // Log.debug("refresh token for \(project.id)")
            self.retrieveToken(for: projectId) { [weak self] tokenData in
                if let tokenData = tokenData {
                    self?.lock.writing { [weak self] in
                        self?.projectTokens[projectId] = tokenData
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            self.startRefreshTimer()
        }
    }

    private func retrieveToken(for projectId: Identifier<Project>, _ date: Date? = nil, completion: @escaping @Sendable (TokenData?) -> Void) {
        if let appUser = Snabble.shared.appUser {
            if verboseToken { Log.debug("retrieveToken p=\(projectId.rawValue) app=\(self.appId) client=\(Snabble.clientId) au=\(appUser), date=\(String(describing: date))") }
            self.retrieveTokenForUser(for: projectId, appUser, date, completion: completion)
        } else {
            if verboseToken { Log.debug("retrieveToken+User p=\(projectId.rawValue) app=\(self.appId) client=\(Snabble.clientId) date=\(String(describing: date))") }
            self.retrieveAppUserAndToken(for: projectId, date, completion: completion)
        }
    }

    private func retrieveAppUserAndToken(for projectId: Identifier<Project>, _ date: Date? = nil, completion: @escaping @Sendable (TokenData?) -> Void) {
        guard let project = Snabble.shared.project(for: projectId) else {
            return completion(nil)
        }

        let url = Snabble.shared.metadata.links.createAppUser.href
        let parameters = [ "project": projectId.rawValue ]
        project.request(.post, url, jwtRequired: false, parameters: parameters, timeout: 5) { request in
            guard
                var request = request,
                let password = self.generatePassword(date)
            else {
                return completion(nil)
            }
            let data = Data("\(self.appId):\(password)".utf8)
            let base64 = data.base64EncodedString()
            request.addValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            request.cachePolicy = .reloadIgnoringCacheData

            project.perform(request) { (result: Result<AppUserResponse, SnabbleError>, httpResponse) in
                switch result {
                case .success(let appUserData):
                    if self.verboseToken { Log.debug("retrieveAppUserAndToken succeeded") }
                    self.verboseToken = false
                    print(#function, "new appUserID: \(appUserData.appUser.id)")
                    Snabble.shared.appUser = AppUser(id: appUserData.appUser.id, secret: appUserData.appUser.secret)
                    completion(TokenData(appUserData.token, projectId))
                case .failure:
                    self.verboseToken = true && Snabble.debugMode
                    if self.verboseToken { Log.debug("retrieveAppUserAndToken failed") }
                    if let response = httpResponse, response.statusCode == 403, date == nil {
                        self.retryWithServerDate(projectId, response, completion: completion)
                        return
                    }
                    completion(nil)
                }
            }
        }
    }

    private func retrieveTokenForUser(for projectId: Identifier<Project>, _ appUser: AppUser, _ date: Date? = nil, completion: @escaping @Sendable (TokenData?) -> Void ) {
        guard let project = Snabble.shared.project(for: projectId) else {
            return completion(nil)
        }

        let parameters = [ "role": "retailerApp" ]

        let url = project.links.tokens.href
        project.request(.get, url, jwtRequired: false, parameters: parameters, timeout: 5) { request in
            guard
                var request = request,
                let password = self.generatePassword(date)
            else {
                return completion(nil)
            }
            let data = Data("\(self.appId):\(password):\(appUser.id):\(appUser.secret)".utf8)
            let base64 = data.base64EncodedString()
            request.addValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            request.cachePolicy = .reloadIgnoringCacheData

            project.perform(request) { (result: Result<TokenResponse, SnabbleError>, httpResponse) in
                switch result {
                case .success(let token):
                    if self.verboseToken { Log.debug("retrieveTokenForUser succeeded") }
                    self.verboseToken = false
                    completion(TokenData(token, projectId))
                case .failure:
                    self.verboseToken = true && Snabble.debugMode
                    if self.verboseToken { Log.debug("retrieveTokenForUser failed") }
                    if let response = httpResponse, response.statusCode == 403, date == nil {
                        self.retryWithServerDate(projectId, response, completion: completion)
                        return
                    }
                    completion(nil)
                }
            }
        }
    }

    private func retryWithServerDate(_ projectId: Identifier<Project>, _ response: HTTPURLResponse, completion: @escaping @Sendable (TokenData?) -> Void ) {
        // not authorized. try again with the content of the the server's "Date" header
        if let serverDate = response.allHeaderFields["Date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_Posix")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: serverDate) {
                if self.verboseToken { Log.debug("retry w/server date: \(date)") }
                self.retrieveToken(for: projectId, date, completion: completion)
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }

    private func generatePassword(_ date: Date? = nil) -> String? {
        guard let secretData = base32DecodeToData(secret),
              let totp = TOTP(secret: secretData, digits: 8, timeInterval: 30, algorithm: .sha256) else {
            return nil
        }

        let date = date ?? Date()
        let pass = totp.generate(time: date)
        if verboseToken { Log.debug("TOTP for \(date) = \(String(describing: pass))") }
        return pass
    }
}
