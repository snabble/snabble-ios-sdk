//
//  RegisterEndpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import SwiftOTP

extension Endpoints {
    enum AppUser {
        static func post(appId: String, appSecret: String) -> Endpoint<UsersResponse> {
            var endpoint: Endpoint<UsersResponse> = .init(
                path: "/apps/\(appId)/users",
                method: .post(nil),
                parse: { data in
                    try Endpoints.jsonDecoder.decode(UsersResponse.self, from: data)
                }
            )
            if let authorization = authorization(appId: appId, appSecret: appSecret) {
                endpoint.headerFields = ["Authorization": "Basic \(authorization)"]
            }
            return endpoint
        }

        private static func authorization(appId: String, appSecret: String) -> String? {
            guard let password = password(withSecret: appSecret, forDate: Date()) else { return nil }
            return "\(appId):\(password)".data(using: .utf8)?.base64EncodedString()
        }

        private static func password(withSecret secret: String, forDate date: Date) -> String? {
            guard
                let secretData = base32DecodeToData(secret),
                let totp = TOTP(secret: secretData, digits: 8, timeInterval: 30, algorithm: .sha256)
            else {
                return nil
            }
            return totp.generate(time: date)
        }
    }
}

struct UsersResponse: Codable {
    let appUser: AppUser
}
