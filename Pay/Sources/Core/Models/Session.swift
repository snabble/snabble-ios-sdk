//
//  Session.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-31.
//

import Foundation
import Tagged
import SnabblePayNetwork

/// The Session is the beginning a potentiel payment process
public struct Session {
    /// Unique identifier of a session
    public let id: ID
    /// The data for the QR code, which must be presented at the point of sale
    public let token: Token
    /// The associated account to the session
    public let account: Account
    /// Date of creation
    public let createdAt: Date
    /// If a token has been presented at the point of sale a transaction might have been started
    public let transaction: Transaction?
    /// After this date the session cannot be used to create a transaction
    public let expiresAt: Date

    /// Type Safe Identifier
    public typealias ID = Tagged<Session, String>
}

extension Session {
    /// The object for the QR code, which must be presented at the point of sale
    public struct Token {
        /// Unique identifier of the token
        public let id: ID
        /// The string for the QR code, which must be presented at the point of sale
        public let value: String
        /// Date of creation
        public let createdAt: Date
        /// Date as soon as the token should be updated. See `SnabblePay.refreshToken(withSessionId:)`.
        public let refreshAt: Date
        /// After this date the token can be used to find the linked session
        public let expiresAt: Date

        /// Type Safe Identifier
        public typealias ID = Tagged<Token, String>
    }
}

extension Session.Token: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Session.Token) {
        self.id = ID(dto.id)
        self.value = dto.value
        self.createdAt = dto.createdAt
        self.refreshAt = dto.refreshAt
        self.expiresAt = dto.expiresAt
    }
}

extension Session: FromDTO {
    init(fromDTO dto: SnabblePayNetwork.Session) {
        self.id = ID(dto.id)
        self.token = .init(fromDTO: dto.token)
        self.account = .init(fromDTO: dto.account)
        self.createdAt = dto.createdAt
        self.expiresAt = dto.expiresAt
        if let transaction = dto.transaction {
            self.transaction = .init(fromDTO: transaction)
        } else {
            self.transaction = nil
        }
    }
}

extension SnabblePayNetwork.Session: ToModel {
    func toModel() -> Session {
        .init(fromDTO: self)
    }
}

extension SnabblePayNetwork.Session.Token: ToModel {
    func toModel() -> Session.Token {
        .init(fromDTO: self)
    }
}
