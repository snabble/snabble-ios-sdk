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

public struct ShopService: Codable {
    public let serviceId: String
    public let iconPath: String
    public let translations: [String: String]
    
    public var germanTranslation: String? {
        translations["de"]
    }
    
    public var englishTranslation: String? {
        translations["en"]
    }
    
    public func translation(for language: String) -> String? {
        guard let translation = translations[language] else {
            return englishTranslation
        }
        guard !translation.isEmpty else {
            return englishTranslation
        }
        return translation
    }
    
    enum CodingKeys: String, CodingKey {
        case serviceId = "serviceID"
        case iconPath = "iconURL"
        case translations
    }
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
        Snabble.shared.project(for: projectId)
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
    
    /// Shop service
    public let shopServices: [ShopService]
    
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
        case services, shopServices, openingHoursSpecification, email, phone, city, street
        case postalCode = "zip", state, country, countryCode
        case customerNetworks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(.id)
        self.name = try container.decode(.name)
        self.projectId = try container.decode(.projectId)
        self.externalId = try container.decodeIfPresent(.externalId)
        self.external = try container.decodeIfPresent([String: Any].self, forKey: .external)
        self.latitude = try container.decode(.latitude)
        self.longitude = try container.decode(.longitude)
        self.services = try container.decode(.services)
        self.shopServices = try container.decodeIfPresent(.shopServices) ?? []
        self.openingHoursSpecification = try container.decode(.openingHoursSpecification)
        self.email = try container.decode(.email)
        self.phone = try container.decode(.phone)
        self.city = try container.decode(.city)
        self.street = try container.decode(.street)
        self.postalCode = try container.decode(.postalCode)
        self.state = try container.decode(.state)
        self.country = try container.decode(.country)
        self.countryCode = try container.decodeIfPresent(.countryCode)
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
        try container.encode(self.shopServices, forKey: .shopServices)
        try container.encode(self.openingHoursSpecification, forKey: .openingHoursSpecification)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.phone, forKey: .phone)
        try container.encode(self.city, forKey: .city)
        try container.encode(self.street, forKey: .street)
        try container.encode(self.postalCode, forKey: .postalCode)
        try container.encode(self.state, forKey: .state)
        try container.encode(self.country, forKey: .country)
        try container.encodeIfPresent(self.countryCode, forKey: .countryCode)
        try container.encodeIfPresent(self.customerNetworks, forKey: .customerNetworks)
    }

    // only used for unit tests!
    internal init(id: Identifier<Shop>, projectId: Identifier<Project>) {
        self.id = id
        self.name = "Snabble Shop"
        self.projectId = projectId
        self.externalId = nil
        self.external = nil
        self.latitude = 10
        self.longitude = 20
        self.services = []
        self.shopServices = []
        self.openingHoursSpecification = []
        self.email = "info@snabble.io"
        self.phone = "0228123456"
        self.city = "Bonn"
        self.street = "Am Dickobskreuz 10"
        self.postalCode = "53121"
        self.state = "NRW"
        self.country = "Deutschland"
        self.countryCode = "de"
        self.customerNetworks = nil
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
