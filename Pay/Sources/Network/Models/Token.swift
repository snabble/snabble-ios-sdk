//
//  Token.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-01.
//

import Foundation

struct Token: Decodable, Sendable {
    let value: String
    let expiresAt: Date
    let scope: Scope
    let type: `Type`

    enum Scope: String, Decodable, Sendable {
        case all
    }

    enum `Type`: String, Decodable, Sendable {
        case bearer = "Bearer"
    }

    enum CodingKeys: String, CodingKey {
        case value = "accessToken"
        case expiresAt
        case scope
        case type = "tokenType"
    }

    func isValid() -> Bool {
        return expiresAt.timeIntervalSinceNow.sign == .plus
    }
}
