//
//  User.swift
//  
//
//  Created by Andreas Osberghaus on 2024-05-27.
//

import Foundation

public struct User: Codable {
    public let firstname: String?
    public let lastname: String?
    public let email: String?
    public let street: String?
    public let zip: String?
    public let city: String?
    public let country: String?
    public let state: String?
    
    public init(firstname: String?, lastname: String?, email: String?, street: String?, zip: String?, city: String?, country: String?, state: String?) {
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.street = street
        self.zip = zip
        self.city = city
        self.country = country
        self.state = state
    }
}

extension User {
    public static func get(forConfig config: Configuration) -> User? {
        guard let data = UserDefaults.standard.data(forKey: "Snabble.user.\(config.domainName)") else { return nil }
        let jsonDecoder = JSONDecoder()
        do {
            return try jsonDecoder.decode(User.self, from: data)
        } catch {
            return nil
        }
    }
    
    public static func set(_ user: User?, forConfig config: Configuration) {
        do {
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: "Snabble.user.\(config.domainName)")
        } catch {
            UserDefaults.standard.set(nil, forKey: "Snabble.user.\(config.domainName)")
        }
    }
}
