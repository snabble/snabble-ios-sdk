//
//  Credentials.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-01.
//

import Foundation

public struct Credentials: Decodable {
    public let identifier: String
    public let secret: String

    enum CodingKeys: String, CodingKey {
        case identifier = "appIdentifier"
        case secret = "appSecret"
    }

    public init(identifier: String, secret: String) {
        self.identifier = identifier
        self.secret = secret
    }
}
