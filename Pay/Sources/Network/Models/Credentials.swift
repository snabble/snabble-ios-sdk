//
//  Credentials.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-01.
//

import Foundation

public struct Credentials: Decodable, Sendable {
    public let identifier: String
    public let secret: String

    public init(identifier: String, secret: String) {
        self.identifier = identifier
        self.secret = secret
    }
}
