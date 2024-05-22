//
//  User.swift
//  
//
//  Created by Andreas Osberghaus on 2024-02-14.
//

import Foundation

public struct User: Codable, Identifiable {
    public let id: String
    public let phoneNumber: String?
    public let details: Details?
    public let fields: [Field]?
    public let consent: Consent?
    
    enum CodingKeys: String, CodingKey {
        case id
        case phoneNumber
        case details
        case fields = "detailFields"
        case consent = "currentConsent"
    }
    
    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.details = try container.decodeIfPresent(Details.self, forKey: .details)
        self.fields = try container.decodeIfPresent([Field].self, forKey: .fields)
        self.consent = try container.decodeIfPresent(Consent.self, forKey: .consent)
    }
    
    public struct Details: Codable, Equatable {
        public let firstName: String?
        public let lastName: String?
        public let email: String?
        public let dateOfBirth: String?
        public let street: String?
        public let zip: String?
        public let city: String?
        public let country: String?
        public let state: String?

        public init(firstName: String?,
                    lastName: String?,
                    email: String?,
                    dateOfBirth: String?,
                    street: String?,
                    zip: String?,
                    city: String?,
                    country: String?,
                    state: String?) {
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.dateOfBirth = dateOfBirth
            self.street = street
            self.zip = zip
            self.city = city
            self.country = country
            self.state = state
        }
    }
    
    public struct Field: Codable, Identifiable, Equatable {
        public let id: String
        public let isRequired: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case isRequired = "required"
        }
    }
    
    public struct Consent: Codable, Equatable {
        public let major: Int
        public let minor: Int
        
        public var version: String {
            "\(major).\(minor)"
        }
        
        enum CodingKeys: String, CodingKey {
            case version
        }
        
        /// Consent initialiser with version string
        /// - Parameter version: The format must be "x.x" or "x"
        public init(version: String) {
            let components: [Int] = version
                .components(separatedBy: ".")
                .map { Int($0) ?? 0 }
            self.major = components.first ?? 0
            self.minor = components.last ?? 0
        }
        
        public init(major: Int, minor: Int = 0) {
            self.major = major
            self.minor = minor
        }
        
        public init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            self.init(version: try container.decode(String.self, forKey: .version))
        }
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(version, forKey: .version)
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.version == rhs.version
        }
    }
}

extension User: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension User {
    public init(user: User, details: User.Details) {
        self.id = user.id
        self.phoneNumber = user.phoneNumber
        self.details = details
        self.fields = user.fields
        self.consent = user.consent
    }
    public init(user: User, consent: User.Consent) {
        self.id = user.id
        self.phoneNumber = user.phoneNumber
        self.details = user.details
        self.fields = user.fields
        self.consent = consent
    }
}
