//
//  User.swift
//  
//
//  Created by Andreas Osberghaus on 2024-05-27.
//

import Foundation

public struct User: Codable {
    public var fullName: String?
    public var firstname: String?
    public var lastname: String?
    public var email: String?
    public var phone: String?
    public var dateOfBirth: Date?
    public var address: Address
    
    enum CodingKeys: String, CodingKey {
        case fullName = "name", firstname, lastname, email, phone = "phoneNumber", dateOfBirth, address
    }
    public struct Address: Codable {
        public var street: String?
        public var zip: String?
        public var city: String?
        public var country: String?
        public var state: String?
    }
}

extension User {
    public init(firstname: String?,
                lastname: String?,
                email: String?,
                phone: String?,
                dateOfBirth: Date?,
                street: String?,
                zip: String?,
                city: String?,
                country: String?,
                state: String?) {        
        let address = Address(street: street, zip: zip, city: city, country: country, state: state)
        self.init(firstname: firstname, lastname: lastname, email: email, phone: phone, dateOfBirth: dateOfBirth, address: address)
    }
    
    public init(firstname: String?,
                lastname: String?,
                email: String?,
                phone: String?,
                dateOfBirth: Date?,
                address: Address) {
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        
        self.address = address
    }

    public init(fullName: String?,
                email: String?,
                phone: String?,
                dateOfBirth: Date?,
                street: String?,
                zip: String?,
                city: String?,
                country: String?,
                state: String?) {
        let address = Address(street: street, zip: zip, city: city, country: country, state: state)

        self.init(fullName: fullName, email: email, phone: phone, dateOfBirth: dateOfBirth, address: address)
    }

    public init(fullName: String?,
                email: String?,
                phone: String?,
                dateOfBirth: Date?,
                address: User.Address) {
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.dateOfBirth = dateOfBirth
        self.address = address
    }

    public init() {
        self.init(firstname: nil,
                  lastname: nil,
                  email: nil,
                  phone: nil,
                  dateOfBirth: nil,
                  street: nil,
                  zip: nil,
                  city: nil,
                  country: nil,
                  state: nil)
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
