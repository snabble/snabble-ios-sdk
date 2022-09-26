//
//  PayoneTokenization.swift
//  Snabble
//
//  Created by Gereon Steffens on 27.09.21.
//

import Foundation

// data we get to perform initial tokenization
public struct PayoneTokenization: Decodable {
    public let merchantID: String
    public let portalID: String
    public let accountID: String
    public let hash: String
    public let isTesting: Bool?

    public let preAuthInfo: PreAuthInfo
    public let links: PayoneLinks

    public struct PreAuthInfo: Decodable {
        public let amount: Int
        public let currency: String
    }

    public struct PayoneLinks: Decodable {
        public let preAuth: Link
    }
}

// data we send to begin the pre-auth
public struct PayonePreAuthData: Encodable {
    public let pseudoCardPAN: String
    public let lastname: String
    
    public init(pseudoCardPAN: String, lastname: String) {
        self.pseudoCardPAN = pseudoCardPAN
        self.lastname = lastname
    }
}

// response from POSTing the auth data
public struct PayonePreAuthResult: Decodable {
    public let status: PayonePreAuthStatus
    let userID: String
    public let links: PayonePreAuthLinks

    public struct PayonePreAuthLinks: Decodable {
        public let scaChallenge: Link
        public let preAuthStatus: Link
        public let redirectSuccess: Link
        public let redirectError: Link
        public let redirectBack: Link
    }
}

// response from querying the `preAuthStatus` endpoint
public struct PayonePreAuthStatusResult: Decodable {
    public let status: PayonePreAuthStatus
}

public enum PayonePreAuthStatus: String, Decodable, UnknownCaseRepresentable {
    case unknown

    case pending
    case successful
    case failed

    public static let unknownCase = Self.unknown
}
