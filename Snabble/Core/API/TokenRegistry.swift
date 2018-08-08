//
//  TokenRegistry.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation
import OneTimePassword
import Base32

// backend response
struct TokenResponse: Decodable {
    let id: String
    let token: String
    let issuedAt: Int64
    let expiresAt: Int64
}

// stored in our token registry
struct TokenData {
    let jwt: String
    let expires: Date
    let refresh: Date

    init(_ response: TokenResponse) {
        self.jwt = response.token
        let expires = Date(timeIntervalSince1970: TimeInterval(response.expiresAt))
        let refreshIn = (expires.timeIntervalSinceReferenceDate - Date.timeIntervalSinceReferenceDate) / 2
        self.expires = expires
        self.refresh = Date(timeIntervalSinceNow: refreshIn)
    }
}

public class TokenRegistry {
    public static let shared = TokenRegistry()

    public var appId = ""
    public var secret = ""

    typealias TokenHandler = (String) -> ()

    private var registry = [String: TokenData]()
    private var inFlight = [String: [TokenHandler]]()
    private var refreshTimer: Timer?

    private init() { }

    /// synchronously return the JWT for the given project, if known
    func token(for project: String) -> String? {
        guard let tokenData = self.registry[project] else {
            return nil
        }

        return tokenData.jwt
    }

    public func getToken(for project: Project, completion: @escaping ()->() ) {
        return self.getTokens(for: [project], completion: completion)
    }
    
    public func getTokens(for projects: [Project], completion: @escaping ()->()) {
        let group = DispatchGroup()

        for project in projects {
            group.enter()
            self.retrieveToken(for: project.id) { tokenData in
                self.registry[project.id] = tokenData
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            self.startRefreshTimer()
            completion()
        }
    }

    public func refreshTokens() {
        let now = Date.timeIntervalSinceReferenceDate - 5
        for (project, tokenData) in self.registry {
            if tokenData.refresh.timeIntervalSinceReferenceDate > now {
                self.retrieveToken(for: project) { tokenData in
                    self.registry[project] = tokenData
                }
            } else {
                print("not refreshing \(project)")
            }
        }
        self.startRefreshTimer()
    }

    private func startRefreshTimer() {
        guard let earliest = self.registry.values.min(by: { $0.refresh < $1.refresh }) else {
            return
        }

        let now = Date()
        let refreshIn = max(earliest.refresh.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate, 1.0)
        print("refresh in \(refreshIn)s -> \(earliest.refresh) \(now)")
        self.refreshTimer?.invalidate()
        self.refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshIn, repeats: false) { timer in
            print("\n\nrefresh start")
            self.refreshTokens()
        }
    }

    private func retrieveToken(for project: String, _ date: Date? = nil, completion: @escaping (TokenData?) -> () ) {
        let parameters = [ "role" : "retailerApp" ]

        SnabbleAPI.request(.get, "/\(project)/tokens", json: true, parameters: parameters, timeout: 2) { request in
            guard
                var request = request,
                let password = self.generatePassword(date),
                let data = "\(self.appId):\(password)".data(using: .utf8)
            else {
                return completion(nil)
            }

            let base64 = data.base64EncodedString()
            request.addValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            request.cachePolicy = .reloadIgnoringCacheData
            SnabbleAPI.perform(request) { (token: TokenResponse?, error, httpResponse) in
                if let token = token {
                    completion(TokenData(token))
                } else {
                    if let response = httpResponse, response.statusCode == 403 {
                        self.retryWithServerDate(project: project, response, completion: completion)
                        return
                    }
                    completion(nil)
                }
            }
        }
    }

    private func retryWithServerDate(project: String, _ response: HTTPURLResponse, completion: @escaping (TokenData?) -> () ) {
        if let serverDate = response.allHeaderFields["Date"] as? String {
            // not authorized. try again with the content of the the server's "Date" header
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_Posix")
            if let date = formatter.date(from: serverDate) {
                self.retrieveToken(for: project, date, completion: completion)
            }
        } else {
            completion(nil)
        }
    }

    private func generatePassword(_ date: Date? = nil) -> String? {
        guard
            let secretData = MF_Base32Codec.data(fromBase32String: self.secret),
            let generator = Generator(factor: .timer(period: 30), secret: secretData, algorithm: .sha256, digits: 8)
        else {
            return nil
        }

        let token = Token(name: "", issuer: "", generator: generator)
        do {
            return try token.generator.password(at: date ?? Date())
        }
        catch {
            return nil
        }
    }

    // unused
    // FIXME synchronize map/array accesses!!!!
    func __token(for project: String, completion: @escaping (String) -> ()) {
        if let tokenData = self.registry[project] {
            return completion(tokenData.jwt)
        } else {
            if self.inFlight.keys.contains(project) {
                // append the completion handler to the already existing in-flight requests
                self.inFlight[project]!.append(completion)
            } else {
                // start a request for this project
                self.inFlight[project] = [completion]
                self.retrieveToken(for: project) { token in
                    self.registry[project] = token
                    if let token = token {
                        for callback in self.inFlight[project]! {
                            callback(token.jwt)
                        }
                    }
                    self.inFlight[project] = nil
                }
            }
        }
    }
}
