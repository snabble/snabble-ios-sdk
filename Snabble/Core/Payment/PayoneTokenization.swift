//
//  PayoneTokenization.swift
//  Snabble
//
//  Created by Gereon Steffens on 27.09.21.
//

import Foundation

// data we get to perform initial tokenization
struct PayoneTokenization: Decodable {
    let merchantID: String
    let portalID: String
    let accountID: String
    let hash: String
    let isTesting: Bool?

    let preAuthInfo: PreAuthInfo
    let links: PayoneLinks

    struct PreAuthInfo: Decodable {
        let amount: Int
        let currency: String
    }

    struct PayoneLinks: Decodable {
        let preAuth: Link
    }
}

// data we send to begin the pre-auth
struct PayonePreAuthData: Encodable {
    let pseudoCardPAN: String
    let lastname: String
}

// response from POSTing the auth data
struct PayonePreAuthResult: Decodable {
    let status: PayonePreAuthStatus
    let userID: String
    let links: PayonePreAuthLinks

    struct PayonePreAuthLinks: Decodable {
        let scaChallenge: Link
        let preAuthStatus: Link
        let redirectSuccess: Link
        let redirectError: Link
        let redirectBack: Link
    }
}

// response from querying the `preAuthStatus` endpoint
struct PayonePreAuthStatusResult: Decodable {
    let status: PayonePreAuthStatus
}

enum PayonePreAuthStatus: String, Decodable, UnknownCaseRepresentable {
    case unknown

    case pending
    case successful
    case failed

    static let unknownCase = Self.unknown
}
