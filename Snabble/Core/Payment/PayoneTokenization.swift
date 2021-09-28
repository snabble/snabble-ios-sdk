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
    let mode: String?
}
