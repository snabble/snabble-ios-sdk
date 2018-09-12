//
//  Metadata.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

public struct Metadata: Decodable {
    public let flags: Flags
    public let projects: [Project]

    enum CodingKeys: String, CodingKey {
        case flags = "metadata"
        case projects
    }

    private init() {
        self.flags = Flags()
        self.projects = [ Project.none ]
    }

    static let none = Metadata()
}

public struct EncodedCodes: Decodable {
    let prefix: String
    let separator: String
    let suffix: String
    let maxCodes: Int

    // optional EAN codes used when splitting into multiple QR codes
    let finalCode: String?          // last code of the last block
    let nextCode: String?           // marker code to indicate "more QR codes"
    let nextCodeWithCheck: String?  // marker code to indicate "more QR codes" + age check required
}

public struct Project: Decodable {
    public let id: String
    public let links: Links
    public let rawLinks: [String: Link]

    public let currency: String
    public let decimalDigits: Int
    public let locale: String
    public let pricePrefixes: [String]
    public let unitPrefixes: [String]
    public let weighPrefixes: [String]
    public let roundingMode: RoundingMode
    public let currencySymbol: String   // not part of JSON, derived from the locale

    public let verifyInternalEanChecksum: Bool
    public let useGermanPrintPrefix: Bool

    // config for embedded QR codes
    public let encodedCodes: EncodedCodes?

    public let shops: [Shop]

    enum CodingKeys: String, CodingKey {
        case id, links
        case currency, decimalDigits, locale, pricePrefixes, unitPrefixes, weighPrefixes, roundingMode
        case verifyInternalEanChecksum, useGermanPrintPrefix, encodedCodes
        case shops
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.links = try container.decode(Links.self, forKey: .links)
        self.rawLinks = try container.decode([String: Link].self, forKey: .links)

        self.currency = try container.decode(.currency)
        self.decimalDigits = try container.decode(.decimalDigits)
        self.locale = try container.decode(.locale)
        self.pricePrefixes = try container.decode(.pricePrefixes)
        self.unitPrefixes = try container.decode(.unitPrefixes)
        self.weighPrefixes = try container.decode(.weighPrefixes)
        self.roundingMode = try container.decode(.roundingMode)

        self.verifyInternalEanChecksum = try container.decode(.verifyInternalEanChecksum)
        self.encodedCodes = try container.decodeIfPresent(.encodedCodes)
        self.useGermanPrintPrefix = try container.decode(.useGermanPrintPrefix)

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: self.locale)
        formatter.currencyCode = self.currency
        formatter.numberStyle = .currency
        self.currencySymbol = formatter.currencySymbol

        self.shops = (try container.decodeIfPresent([Shop].self, forKey: .shops)) ?? []
    }

    private init() {
        self.id = "none"
        self.links = Links.empty
        self.rawLinks = [:]
        self.currency = ""
        self.decimalDigits = 0
        self.locale = ""
        self.pricePrefixes = []
        self.unitPrefixes = []
        self.weighPrefixes = []
        self.roundingMode = .up
        self.verifyInternalEanChecksum = false
        self.encodedCodes = nil
        self.useGermanPrintPrefix = false
        self.currencySymbol = ""
        self.shops = []
    }

    public static let none = Project()
}

/// Link
public struct Link: Decodable {
    public let href: String

    /// empty instance, used for the default init of `MetadataLinks`
    static let empty = Link(href: "")
}

public struct Links: Decodable {
    public let appdb: Link
    public let appEvents: Link
    public let checkoutInfo: Link
    public let productBySku: Link
    public let productByCode: Link
    public let productByWeighItemId: Link
    public let bundlesForSku: Link
    public let productsBySku: Link
    public let tokens: Link

    public static let empty = Links()

    private init() {
        self.appdb = Link.empty
        self.appEvents = Link.empty
        self.checkoutInfo = Link.empty
        self.productBySku = Link.empty
        self.productByCode = Link.empty
        self.productByWeighItemId = Link.empty
        self.bundlesForSku = Link.empty
        self.productsBySku = Link.empty
        self.tokens = Link.empty
    }

    init(appdb: Link, appEvents: Link, checkoutInfo: Link, productBySku: Link, productByCode: Link, productByWeighItemId: Link, bundlesForSku: Link, productsBySku: Link, tokens: Link) {
        self.appdb = appdb
        self.appEvents = appEvents
        self.checkoutInfo = checkoutInfo
        self.productBySku = productBySku
        self.productByCode = productByCode
        self.productByWeighItemId = productByWeighItemId
        self.bundlesForSku = bundlesForSku
        self.productsBySku = productsBySku
        self.tokens = tokens
    }
}

public struct Flags: Decodable {
    public let kill: Bool

    fileprivate init() {
        self.kill = false
    }
}

public enum RoundingMode: String, Decodable {
    case up
    case down
    case commercial

    /// get the appropriate `NSDecimalNumber.RoundingMode`
    var mode: NSDecimalNumber.RoundingMode {
        switch self {
        case .up: return .up
        case .down: return .down
        case .commercial: return .plain
        }
    }
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

// MARK: - loading metadata

public extension Metadata {

    public static func readResource(_ name: String, extension: String) -> Metadata? {
        if let url = Bundle.main.url(forResource: name, withExtension: `extension`) {
            do {
                let data = try Data(contentsOf: url)
                let metadata = try JSONDecoder().decode(Metadata.self, from: data)
                SnabbleAPI.metadata = metadata
                return metadata
            } catch let error {
                NSLog("error parsing app data resource: \(error)")
            }
        }
        return nil
    }

    public static func load(from url: String, _ parameters: [String: String]? = nil, completion: @escaping (Metadata?) -> () ) {
        SnabbleAPI.request(.get, url, jwtRequired: false, parameters: parameters, timeout: 5) { request in
            guard let request = request else {
                return completion(nil)
            }

            SnabbleAPI.perform(request) { (metadata: Metadata?, error) in
                if let metadata = metadata {
                    SnabbleAPI.metadata = metadata
                }

                completion(metadata)
            }
        }
    }
    
}
