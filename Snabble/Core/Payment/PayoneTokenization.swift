//
//  PayoneTokenization.swift
//  Snabble
//
//  Created by Gereon Steffens on 27.09.21.
//

import Foundation

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
