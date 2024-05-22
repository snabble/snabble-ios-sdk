//
//  Session.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-31.
//

import Foundation

public struct Session: Decodable {
    public let id: String
    public let token: Session.Token
    public let account: Account
    public let createdAt: Date
    public let expiresAt: Date
    public let transaction: Transaction?
}

extension Session {
    public struct Token: Decodable {
        public let id: String
        public let value: String
        public let createdAt: Date
        public let refreshAt: Date
        public let expiresAt: Date
    }
}
