//
//  Token.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-02.
//

import Foundation

public struct Token: Codable, Sendable {
    public let id: String
    public let value: String
    public let issuedAt: Date
    public let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case value = "token"
        case issuedAt
        case expiresAt
    }

    public enum Scope: String {
        case retailerApp
        case paymentSystem
        case pointOfSale
        case gatekeeper
    }
    
    public init(id: String, value: String, issuedAt: Date, expiresAt: Date) {
        self.id = id
        self.value = value
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
    }

    public func isValid() -> Bool {
        expiresAt.timeIntervalSinceNow.sign == .plus
    }
}
