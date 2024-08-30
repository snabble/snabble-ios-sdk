//
//  AppUser.swift
//
//
//  Created by Andreas Osberghaus on 2024-08-30.
//

import Foundation

public struct AppUser: Codable {
    public let id: String
    public let secret: String
    
    public init(id: String, secret: String) {
        self.id = id
        self.secret = secret
    }
}
