//
//  Paydirekt.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

// TODO: remove ipAddress and fingerprint
// TODO: if there are multiple bank accounts in one PD account, how/where do we figure out which account to use?

public struct GiropayAuthorization: Encodable, Sendable {
    public let id: String
    public let name: String
    public let ipAddress: String
    public let fingerprint: String

    public let redirectUrlAfterSuccess: String
    public let redirectUrlAfterCancellation: String
    public let redirectUrlAfterFailure: String
    
    public init(id: String, name: String, ipAddress: String, fingerprint: String, redirectUrlAfterSuccess: String, redirectUrlAfterCancellation: String, redirectUrlAfterFailure: String) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.fingerprint = fingerprint
        self.redirectUrlAfterSuccess = redirectUrlAfterSuccess
        self.redirectUrlAfterCancellation = redirectUrlAfterCancellation
        self.redirectUrlAfterFailure = redirectUrlAfterFailure
    }
}
