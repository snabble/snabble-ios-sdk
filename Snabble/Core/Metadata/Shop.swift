//
//  Shop.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

// MARK: - shop data

/// opening hours
public struct OpeningHoursSpecification: Codable {
    public let opens: String
    public let closes: String
    public let dayOfWeek: String
}

/// customer networks
public struct CustomerNetworks: Codable {
    public let ssid: String
}

/// base data for one shop
public struct Shop: Codable, Identifiable {
    /// id of this shop, use this to initialize shopping carts
    public let id: Identifier<Shop>
    /// name of this shop
    public let name: String
    /// snabble project identifier of this shop
    public let projectId: Identifier<Project>

    // snabble `Project` of this shop
    public var project: Project? {
        SnabbleAPI.project(for: projectId)
    }

    /// externally provided identifier
    public let externalId: String?
    /// externally provided data
    public let external: [String: Any]?

    /// latitude
    public let latitude: Double
    /// longitude
    public let longitude: Double

    /// services offered
    public let services: [String]
    /// opening hours
    public let openingHoursSpecification: [OpeningHoursSpecification]

    /// email address
    public let email: String
    /// phone number
    public let phone: String
    /// city
    public let city: String
    /// street
    public let street: String
    /// postal code
    public let postalCode: String
    /// state
    public let state: String
    /// country
    public let country: String
    public let countryCode: String?

    public let customerNetworks: [CustomerNetworks]?

    enum CodingKeys: String, CodingKey {
        case id, name, projectId = "project", externalId, external
        case latitude = "lat", longitude = "lon"
        case services, openingHoursSpecification, email, phone, city, street
        case postalCode = "zip", state, country, countryCode
        case customerNetworks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(.id)
        self.name = try container.decode(.name)
        self.projectId = try container.decode(.projectId)
        self.externalId = try container.decode(.externalId)
        self.external = try container.decodeIfPresent([String: Any].self, forKey: .external)
        self.latitude = try container.decode(.latitude)
        self.longitude = try container.decode(.longitude)
        self.services = try container.decode(.services)
        self.openingHoursSpecification = try container.decode(.openingHoursSpecification)
        self.email = try container.decode(.email)
        self.phone = try container.decode(.phone)
        self.city = try container.decode(.city)
        self.street = try container.decode(.street)
        self.postalCode = try container.decode(.postalCode)
        self.state = try container.decode(.state)
        self.country = try container.decode(.country)
        self.countryCode = try container.decode(.countryCode)
        self.customerNetworks = try container.decodeIfPresent(.customerNetworks)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.projectId, forKey: .projectId)
        try container.encode(self.externalId, forKey: .externalId)
        try container.encode(self.latitude, forKey: .latitude)
        try container.encode(self.longitude, forKey: .longitude)
        try container.encode(self.services, forKey: .services)
        try container.encode(self.openingHoursSpecification, forKey: .openingHoursSpecification)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.phone, forKey: .phone)
        try container.encode(self.city, forKey: .city)
        try container.encode(self.street, forKey: .street)
        try container.encode(self.postalCode, forKey: .postalCode)
        try container.encode(self.state, forKey: .state)
        try container.encode(self.country, forKey: .country)
        try container.encode(self.countryCode, forKey: .countryCode)
        try container.encode(self.customerNetworks, forKey: .customerNetworks)
    }
}

extension Shop: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// response object from the `activeShops` endpoint
struct ActiveShops: Decodable {
    let shops: [Shop]
}
