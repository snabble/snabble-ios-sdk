//
//  User.swift
//  
//
//  Created by Andreas Osberghaus on 2024-05-27.
//

import Foundation

public struct User: Codable {
    public var firstname: String?
    public var lastname: String?
    public var email: String?
    public var phone: String?
    public var street: String?
    public var zip: String?
    public var city: String?
    public var country: String?
    public var state: String?
    
    public init(firstname: String?, lastname: String?, email: String?, phone: String?, street: String?, zip: String?, city: String?, country: String?, state: String?) {
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.phone = phone
        self.street = street
        self.zip = zip
        self.city = city
        self.country = country
        self.state = state
    }
    public init() {
        self.init(firstname: nil, lastname: nil, email: nil, phone: nil, street: nil, zip: nil, city: nil, country: nil, state: nil)
    }
    
}

extension User {
    private static func userKey(forConfig config: Configuration) -> String {
        "Snabble.api.user.\(config.domainName).\(config.appId)"
    }
    
    public static func get(forConfig config: Configuration) -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey(forConfig: config)) else { return nil }
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
            UserDefaults.standard.set(encoded, forKey: userKey(forConfig: config))
        } catch {
            UserDefaults.standard.set(nil, forKey: userKey(forConfig: config))
        }
    }
}
