//
//  Paydirekt.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// TODO: remove ipAddress and fingerprint
// TODO: if there are multiple bank accounts in one PD account, how/where do we figure out which account to use?

public struct PaydirektAuthorization: Encodable {
    let id: String
    let name: String
    let ipAddress: String
    let fingerprint: String

    let redirectUrlAfterSuccess: String
    let redirectUrlAfterCancellation: String
    let redirectUrlAfterFailure: String
}
