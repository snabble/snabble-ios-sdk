//
//  User.swift
//  
//
//  Created by Andreas Osberghaus on 2024-05-27.
//

import Foundation
import SnabbleNetwork

public struct User: Codable {
    public let id: String
    
    public let metadata: Metadata?
    
    public var firstname: String?
    public var lastname: String?
    public var email: String?
    public var phone: Phone?
    public var dateOfBirth: Date?
    public var address: Address?
    
    public struct Phone: Codable {
        public var code: UInt?
        public var number: String?
    }
    public struct Address: Codable {
        public var street: String?
        public var zip: String?
        public var city: String?
        public var country: String?
        public var state: String?
    }
    
    public struct Metadata: Codable {
        public let phoneNumber: String?
        public let fields: [Field]?
        public let consent: Consent?
        
        public init(phoneNumber: String?, fields: [Field]?, consent: Consent?) {
            self.phoneNumber = phoneNumber
            self.fields = fields
            self.consent = consent
        }
    }
    
    public struct Field: Codable, Identifiable, Equatable {
        public let id: String
        public let isRequired: Bool
        
        public init(id: String, isRequired: Bool) {
            self.id = id
            self.isRequired = isRequired
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
        
        public func toNetwork() -> SnabbleNetwork.User.Consent {
            SnabbleNetwork.User.Consent.init(major: major, minor: minor)
        }
    }
    
    public init(
        id: String,
        metadata: Metadata?,
        firstname: String?,
        lastname: String?,
        email: String?,
        phone: Phone?,
        dateOfBirth: Date?,
        address: Address) {
            self.id = id
            self.metadata = metadata
            self.firstname = firstname
            self.lastname = lastname
            self.email = email
            self.phone = phone
            self.dateOfBirth = dateOfBirth

            self.address = address
            
        }
}

extension SnabbleUser.User: Equatable {
    public static func == (lhs: SnabbleUser.User, rhs: SnabbleUser.User) -> Bool {
        lhs.id == rhs.id
    }
}

extension User {
    public init(
        id: String,
        metadata: Metadata?,
        firstname: String?,
        lastname: String?,
        email: String?,
        phone: Phone?,
        dateOfBirth: Date?,
        street: String?,
        zip: String?,
        city: String?,
        country: String?,
        state: String?) {
            let address = Address(street: street, zip: zip, city: city, country: country, state: state)
            self.init(id: id, metadata: metadata, firstname: firstname, lastname: lastname, email: email, phone: phone, dateOfBirth: dateOfBirth, address: address)
    }
    
    public init() {
        self.init(
            id: UUID().uuidString,
            metadata: nil,
            firstname: nil,
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
    public var fullName: String? {
        guard let firstname else {
            return lastname
        }
        guard let lastname else {
            return firstname
        }
        return firstname + " " + lastname
    }

    public var phoneNumber: String? {
        guard let phone, let number = phone.number else {
            return metadata?.phoneNumber
        }
        guard let code = phone.code else {
            return number
        }
        return "+\(code)\(number)"
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
