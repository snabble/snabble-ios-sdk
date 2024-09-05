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
    
    public var firstName: String?
    public var lastName: String?
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
        
        init(street: String? = nil, zip: String? = nil, city: String? = nil, country: String? = nil, state: String? = nil) {
            self.street = street
            self.zip = zip
            self.city = city
            self.country = country
            self.state = state
        }
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
        
        func toDTO() -> UserDTO.Consent {
            UserDTO.Consent.init(major: major, minor: minor)
        }
    }
    
    public init(
        id: String,
        metadata: Metadata?,
        firstName: String?,
        lastName: String?,
        email: String?,
        phone: Phone?,
        dateOfBirth: Date?,
        address: Address) {
            self.id = id
            self.metadata = metadata
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.phone = phone
            self.dateOfBirth = dateOfBirth
            self.address = address
        }
    
    public init(user: User, details: User.Details) {
        self.id = user.id
        self.metadata = user.metadata
        self.firstName = details.firstName
        self.lastName = details.lastName
        self.email = details.email
        self.phone = user.phone
        self.dateOfBirth = details.dateOfBirth?.toDate()
        self.address = details.toAddress()
    }
    
    public init(user: User, consent: User.Consent) {
        self.id = user.id
        self.metadata = .init(
            phoneNumber: user.metadata?.phoneNumber,
            fields: user.metadata?.fields,
            consent: consent
        )
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.email = user.email
        self.phone = user.phone
        self.dateOfBirth = user.dateOfBirth
        self.address = user.address
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
        firstName: String?,
        lastName: String?,
        email: String?,
        phone: Phone?,
        dateOfBirth: Date?,
        street: String?,
        zip: String?,
        city: String?,
        country: String?,
        state: String?) {
            let address = Address(street: street, zip: zip, city: city, country: country, state: state)
            self.init(id: id, metadata: metadata, firstName: firstName, lastName: lastName, email: email, phone: phone, dateOfBirth: dateOfBirth, address: address)
    }
    
    public init() {
        self.init(
            id: UUID().uuidString,
            metadata: nil,
            firstName: nil,
            lastName: nil,
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
        guard let firstName else {
            return lastName
        }
        guard let lastName else {
            return firstName
        }
        return firstName + " " + lastName
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
    private static func userKey(forConfig config: Configurable) -> String {
        "Snabble.api.user.\(config.domainName).\(config.appId)"
    }
    
    public static func get(forConfig config: Configurable) -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey(forConfig: config)) else { return nil }
        let jsonDecoder = JSONDecoder()
        do {
            return try jsonDecoder.decode(User.self, from: data)
        } catch {
            return nil
        }
    }
    
    public static func set(_ user: User?, forConfig config: Configurable) {
        do {
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: userKey(forConfig: config))
        } catch {
            UserDefaults.standard.set(nil, forKey: userKey(forConfig: config))
        }
    }
}

extension User {
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
        
        func toAddress() -> User.Address {
            .init(street: street, zip: zip, city: city, country: country, state: state)
        }
        
        func toDTO() -> UserDTO.Details {
            UserDTO.Details.init(
                firstName: firstName,
                lastName: lastName,
                email: email,
                dateOfBirth: dateOfBirth,
                street: street,
                zip: zip,
                city: city,
                country: country,
                state: state
            )
        }
    }
}

private extension String {
    func toDate(withFormat format: String = "yyyy-MM-dd") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
}

private extension Date {
    func toString(withFormat format: String = "yyyy-MM-dd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

public extension User {
    var isInputRequired: Bool {
        guard let fields = metadata?.fields else {
            return false
        }
        var isInputRequired = false
        for field in fields where field.isRequired {
            let key = field.id
            switch key {
            case "firstName":
                isInputRequired = firstName == nil
            case "lastName":
                isInputRequired = lastName == nil
            case "email":
                isInputRequired = email == nil
            case "street":
                isInputRequired = address?.street == nil
            case "zip":
                isInputRequired = address?.zip == nil
            case "city":
                isInputRequired = address?.city == nil
            case "country":
                isInputRequired = address?.country == nil
            case "dateOfBirth":
                isInputRequired = dateOfBirth == nil
            default:
                continue
            }
            if isInputRequired {
                break
            }
        }
        return isInputRequired
    }
}
