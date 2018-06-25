//
//  Metadata.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

/// Link
public struct Link: Decodable {
    public let href: String
}

public struct MetadataLinks: Decodable {
    public var appdb: Link
    public var checkoutInfo: Link
    public var productBySku: Link
    public var productByCode: Link
    public var productByWeighItemId: Link
}

public struct AppData: Decodable {
    public let links: MetadataLinks
    public let flags: Flags
    public let shops: [Shop]
    public let rawLinks: [String: Link]
    public let project: Project

    enum CodingKeys: String, CodingKey {
        case links
        case flags = "metadata"
        case shops
        case project
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.links = try container.decode(MetadataLinks.self, forKey: .links)
        self.flags = try container.decode(Flags.self, forKey: .flags)
        self.project = try container.decode(Project.self, forKey: .project)
        self.shops = (try container.decodeIfPresent([Shop].self, forKey: .shops)) ?? []

        self.rawLinks = try container.decode([String: Link].self, forKey: .links)
    }
}

public struct Flags: Decodable {
    public let kill: Bool
    public let enableCheckout: Bool
}

public enum RoundingMode: String, Decodable {
    case up
    case down
    case commercial

    var mode: NSDecimalNumber.RoundingMode {
        switch self {
        case .up: return .up
        case .down: return .down
        case .commercial: return .plain
        }
    }
}

public struct Project: Decodable {
    public let currency: String
    public let decimalDigits: Int
    public let locale: String
    public let pricePrefixes: [String]?
    public let unitPrefixes: [String]?
    public let weighPrefixes: [String]?
    public let roundingMode: RoundingMode
}

// MARK: - shop data

/// opening hours
public struct OpeningHoursSpecification: Decodable {
    public let opens: String
    public let closes: String
    public let dayOfWeek: String
}

/// base data for one shop
public struct Shop: Decodable {
    /// id of this shop, use this to initialize shopping carts
    public let id: String
    /// name of this shop
    public let name: String
    /// snabble project identifier of this shop
    public let project: String

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

    /// distance to user's current location (in meters)
    public var distance: Double? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, project, externalId, external
        case latitude = "lat", longitude = "lon"
        case services, openingHoursSpecification, email, phone, city, street
        case postalCode = "zip", state, country
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(.id)
        self.name = try container.decode(.name)
        self.project = try container.decode(.project)
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
    }
}

public extension AppData {

    public static func readResource(_ name: String, extension: String) -> AppData? {
        if let url = Bundle.main.url(forResource: name, withExtension: `extension`) {
            do {
                let data = try Data(contentsOf: url)
                let appData = try JSONDecoder().decode(AppData.self, from: data)
                return appData
            } catch let error {
                NSLog("error parsing app data resource: \(error)")
            }
        }
        return nil
    }

    public static func load(from url: String, _ parameters: [String: String]? = nil, completion: @escaping (AppData?) -> () ) {
        guard let request = SnabbleAPI.request(.get, url, parameters: parameters, timeout: 0) else {
            return completion(nil)
        }
        SnabbleAPI.perform(request) { (appData: AppData?) in
            completion(appData)
        }
    }

}
