//
//  TokenRegistry.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation
import OneTimePassword
import Base32

struct TokenData {
    let jwt: String
    let expires: Date
}

struct TokenResponse: Decodable {
    let id: String
    let token: String
    let issuedAt: Int64
    let expiresAt: Int64
}

public class TokenRegistry {
    public static let shared = TokenRegistry()

    public var appId = ""
    public var secret = ""

    typealias TokenHandler = (String) -> ()

    private var registry = [String: TokenData]()
    private var inFlight = [String: [TokenHandler]]()

    private init() { }

    /// synchronously return the JWT for the given project, if known
    func jwtFor(_ project: String) -> String? {
        return self.registry[project]?.jwt
    }

    public func getAllTokens(completion: @escaping ()->()) {
        let group = DispatchGroup()

        for project in APIConfig.shared.metadata.projects {
            group.enter()
            self.retrieveToken(for: project.id) { tokenData in
                self.registry[project.id] = tokenData
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion()
        }
    }

    // unused
    // FIXME synchronize map/array accesses!!!!
    func __token(for project: String, completion: @escaping (String) -> ()) {
        if let tokenData = self.registry[project] {
            return completion(tokenData.jwt)
        } else {
            if self.inFlight.keys.contains(project) {
                // append the completion handler to the alread existing in-flight requests
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

    func retrieveToken(for project: String, completion: @escaping (TokenData?) -> () ) {
        let parameters = [ "role" : "retailerApp" ]
        guard
            var request = SnabbleAPI.request(.get, "/\(project)/tokens", json: true, parameters: parameters, timeout: 2),
            let password = self.generatePassword(),
            let data = "\(self.appId):\(password)".data(using: .utf8)
        else {
            return completion(nil)
        }

        let base64 = data.base64EncodedString()
        request.addValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        SnabbleAPI.perform(request) { (result: TokenResponse?, error) in
            if let token = result {
                let expires = Date(timeIntervalSince1970: TimeInterval(token.expiresAt))
                completion(TokenData(jwt: token.token, expires: expires))
            } else {
                completion(nil)
            }
        }
    }

    private func generatePassword() -> String? {
        guard
            let secretData = MF_Base32Codec.data(fromBase32String: self.secret),
            let generator = Generator(factor: .timer(period: 30), secret: secretData, algorithm: .sha256, digits: 8)
        else {
            return nil
        }

        let token = Token(name: "", issuer: "", generator: generator)
        do {
            let now = Date()
            return try token.generator.password(at: now)
        }
        catch {
            return nil
        }
    }
}
