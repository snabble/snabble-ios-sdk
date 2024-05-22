//
//  Token.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-01.
//

import Foundation

struct Token: Decodable {
    let value: String
    let expiresAt: Date
    let scope: Scope
    let type: `Type`

    enum Scope: String, Decodable {
        case all
    }

    enum `Type`: String, Decodable {
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
