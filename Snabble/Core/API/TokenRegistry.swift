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
    let url: String

    init(_ response: TokenResponse, _ url: String) {
        self.jwt = response.token
        let expires = Date(timeIntervalSince1970: TimeInterval(response.expiresAt))
        let refreshIn = (expires.timeIntervalSinceReferenceDate - Date.timeIntervalSinceReferenceDate) / 2
        self.expires = expires
        self.refresh = Date(timeIntervalSinceNow: refreshIn)
        self.url = url
    }
}

public class TokenRegistry {
    public static let shared = TokenRegistry()

    public var appId = ""
    public var secret = ""

    private var registry = [String: TokenData]()
    private var refreshTimer: Timer?

    private init() { }

    public func getToken(for projectId: String, from url: String, completion: @escaping (String?)->() ) {
        if let token = self.registry[projectId] {
            // we already have a token
            return completion(token.jwt)
        }

        // no token in our registry, go fetch it
        self.retrieveToken(from: url) { tokenData in
            if let tokenData = tokenData {
                self.registry[projectId] = tokenData
                self.startRefreshTimer()
                completion(tokenData.jwt)
            } else {
                completion(nil)
            }
        }
    }

    private func startRefreshTimer() {
        guard let earliest = self.registry.values.min(by: { $0.refresh < $1.refresh }) else {
            return
        }

        let now = Date()
        let refreshIn = max(earliest.refresh.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate, 1.0)
        self.refreshTimer?.invalidate()
        self.refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshIn, repeats: false) { timer in
            self.refreshTokens()
        }
    }

    private func refreshTokens() {
        let now = Date.timeIntervalSinceReferenceDate - 5
        for (project, tokenData) in self.registry {
            if tokenData.refresh.timeIntervalSinceReferenceDate > now {
                self.retrieveToken(from: tokenData.url) { tokenData in
                    if let tokenData = tokenData {
                        self.registry[project] = tokenData
                    }
                }
            }
        }
        self.startRefreshTimer()
    }

    private func retrieveToken(from url: String, _ date: Date? = nil, completion: @escaping (TokenData?) -> () ) {
        let parameters = [ "role" : "retailerApp" ]

        SnabbleAPI.request(.get, url, jwtRequired: false, parameters: parameters, timeout: 2) { request in
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
                    completion(TokenData(token, url))
                } else {
                    if let response = httpResponse, response.statusCode == 403 {
                        self.retryWithServerDate(url, response, completion: completion)
                        return
                    }
                    completion(nil)
                }
            }
        }
    }

    private func retryWithServerDate(_ url: String, _ response: HTTPURLResponse, completion: @escaping (TokenData?) -> () ) {
        if let serverDate = response.allHeaderFields["Date"] as? String {
            // not authorized. try again with the content of the the server's "Date" header
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_Posix")
            if let date = formatter.date(from: serverDate) {
                self.retrieveToken(from: url, date, completion: completion)
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
    
}
