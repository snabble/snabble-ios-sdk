//
//  Metadata.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

public struct Metadata: Decodable {
    public let flags: Flags
    public let projects: [Project]
    public let gatewayCertificates: [GatewayCertificate]
    public let links: MetadataLinks

    enum CodingKeys: String, CodingKey {
        case flags = "metadata"
        case projects, gatewayCertificates, links, templates
    }

    private init() {
        self.flags = Flags()
        self.projects = [ Project.none ]
        self.gatewayCertificates = []
        self.links = MetadataLinks()
    }

    static let none = Metadata()

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.flags = try container.decode(Flags.self, forKey: .flags)
        self.projects = try container.decode([Project].self, forKey: .projects)
        let certs = try container.decodeIfPresent([GatewayCertificate].self, forKey: .gatewayCertificates)
        self.gatewayCertificates = certs ?? []
        self.links = try container.decode(MetadataLinks.self, forKey: .links)
    }
}

public struct TemplateDefinition: Decodable {
    public let id: String
    public let template: String

    static func arrayFrom(_ templates: [String: String]?) -> [TemplateDefinition] {
        guard let templates = templates else {
            return []
        }

        let result: [TemplateDefinition] = templates.reduce(into: []) { result, entry in
            result.append(TemplateDefinition(id: entry.key, template: entry.value))
        }
        return result
    }
}

public struct GatewayCertificate: Decodable {
    public let value: String
    public let validUntil: String // iso8601 date

    public var data: Data? {
        return Data(base64Encoded: self.value)
    }
}

public struct MetadataLinks: Decodable {
    public let clientOrders: Link?
    public let appUser: Link
    public let appUserOrders: Link
    public let telecashSecret: Link?
    public let telecashPreauth: Link?
    public let paydirektCustomerAuthorization: Link?
    public let createAppUser: Link
    public let `self`: Link

    fileprivate init() {
        self.clientOrders = nil
        self.appUser = Link.empty
        self.appUserOrders = Link.empty
        self.createAppUser = Link.empty
        self.`self` = Link.empty

        self.telecashSecret = nil
        self.telecashPreauth = nil
        self.paydirektCustomerAuthorization = nil
    }
}

public enum QRCodeFormat: String, Decodable, UnknownCaseRepresentable {
    case unknown

    case simple
    // swiftlint:disable:next identifier_name
    case csv_globus // simple header, deprecated
    case csv        // new format with "x of y" header info
    case ikea

    var repeatCodes: Bool {
        switch self {
        case .csv, .csv_globus: return false
        case .ikea, .simple: return true
        case .unknown: return true
        }
    }

    public static let unknownCase = QRCodeFormat.unknown
}

public struct QRCodeConfig: Decodable {
    let format: QRCodeFormat

    let prefix: String
    let separator: String
    let suffix: String
    let maxCodes: Int

    // optional EAN codes used when splitting into multiple QR codes
    let finalCode: String?          // last code of the last block
    let nextCode: String?           // marker code to indicate "more QR codes"
    let nextCodeWithCheck: String?  // marker code to indicate "more QR codes" + age check required

    // when maxCodes is not sufficiently precise, maxChars imposes a string length limit
    let maxChars: Int?

    var effectiveMaxCodes: Int {
        let leaveRoom = self.nextCode != nil || self.nextCodeWithCheck != nil || self.finalCode != nil
        return self.maxCodes - (leaveRoom ? 1 : 0)
    }

    enum CodingKeys: String, CodingKey {
        case format
        case prefix, separator, suffix, maxCodes, maxChars
        case finalCode, nextCode, nextCodeWithCheck
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.format = try container.decode(QRCodeFormat.self, forKey: .format)

        self.prefix = try container.decodeIfPresent(String.self, forKey: .prefix) ?? ""
        self.separator = try container.decodeIfPresent(String.self, forKey: .separator) ?? "\n"
        self.suffix = try container.decodeIfPresent(String.self, forKey: .suffix) ?? ""
        self.maxCodes = try container.decodeIfPresent(Int.self, forKey: .maxCodes) ?? 100

        self.maxChars = try container.decodeIfPresent(Int.self, forKey: .maxChars)
        self.finalCode = try container.decodeIfPresent(String.self, forKey: .finalCode)
        self.nextCode = try container.decodeIfPresent(String.self, forKey: .nextCode)
        self.nextCodeWithCheck = try container.decodeIfPresent(String.self, forKey: .nextCodeWithCheck)
    }

    init(format: QRCodeFormat,
         prefix: String = "", separator: String = "\n", suffix: String = "", maxCodes: Int = 100,
         maxChars: Int? = nil, finalCode: String? = nil, nextCode: String? = nil, nextCodeWithCheck: String? = nil) {
        self.format = format
        self.prefix = prefix
        self.separator = separator
        self.suffix = suffix
        self.maxCodes = maxCodes
        self.maxChars = maxChars
        self.finalCode = finalCode
        self.nextCode = nextCode
        self.nextCodeWithCheck = nextCodeWithCheck
    }

}

public enum ScanFormat: String, Decodable, CaseIterable {
    // 1d codes
    case ean13      // includes UPC-A
    case ean8
    case code128
    case itf14
    case code39

    // 2d codes
    case qr
    case dataMatrix = "datamatrix"
}

public struct CustomerCardInfo: Decodable {
    public let required: String?
    public let accepted: [String]?

    init(_ required: String? = nil, _ accepted: [String]? = nil) {
        self.required = required
        self.accepted = accepted
    }
}

public struct PriceOverrideCode: Decodable {
    public let id: String
    public let template: String
    public let lookupTemplate: String?
    public let transmissionTemplate: String?
    public let transmissionCode: String?
}

public struct CheckoutLimits: Decodable {
    let notAllMethodsAvailable: Int?
    let checkoutNotAvailable: Int?
}

public struct ProjectMessages: Decodable {
    public let sepaMandate: String?
    public let sepaMandateShort: String?
}

public struct Project: Decodable {
    public let id: String
    public let name: String
    public let links: ProjectLinks
    public let rawLinks: [String: Link]

    public let currency: String
    public let decimalDigits: Int
    public let locale: String
    public let roundingMode: RoundingMode
    public let currencySymbol: String   // not part of JSON, derived from the locale

    // config for embedded QR codes
    public let qrCodeConfig: QRCodeConfig?

    public let scanFormats: [ScanFormat]

    public let shops: [Shop]

    public let customerCards: CustomerCardInfo?

    public let codeTemplates: [TemplateDefinition]
    public let searchableTemplates: [String]?

    public let priceOverrideCodes: [PriceOverrideCode]?

    public let checkoutLimits: CheckoutLimits?

    public let messages: ProjectMessages?
    public let paymentMethods: [RawPaymentMethod]

    enum CodingKeys: String, CodingKey {
        case id, name, links
        case currency, decimalDigits, locale, roundingMode
        case qrCodeConfig = "qrCodeOffline"
        case shops, scanFormats, customerCards, codeTemplates, searchableTemplates, priceOverrideCodes, checkoutLimits
        case messages = "texts"
        case paymentMethods
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.links = try container.decode(ProjectLinks.self, forKey: .links)
        self.rawLinks = try container.decode([String: Link].self, forKey: .links)

        self.currency = try container.decode(.currency)
        self.decimalDigits = try container.decode(.decimalDigits)
        self.locale = try container.decode(.locale)
        self.roundingMode = try container.decode(.roundingMode)

        self.qrCodeConfig = try container.decodeIfPresent(.qrCodeConfig)

        self.currencySymbol = Self.currencySymbol(for: self.currency, locale: self.locale)

        self.shops = (try container.decodeIfPresent([Shop].self, forKey: .shops)) ?? []

        let defaultFormats = [ ScanFormat.ean8.rawValue, ScanFormat.ean13.rawValue, ScanFormat.code128.rawValue ]
        let formats = (try container.decodeIfPresent([String].self, forKey: .scanFormats)) ?? defaultFormats
        self.scanFormats = formats.compactMap { ScanFormat(rawValue: $0) }
        self.customerCards = try container.decodeIfPresent(CustomerCardInfo.self, forKey: .customerCards)
        let templates = try container.decodeIfPresent([String: String].self, forKey: .codeTemplates)
        self.codeTemplates = TemplateDefinition.arrayFrom(templates)
        self.searchableTemplates = try container.decodeIfPresent([String].self, forKey: .searchableTemplates)
        self.priceOverrideCodes = try container.decodeIfPresent([PriceOverrideCode].self, forKey: .priceOverrideCodes)
        self.checkoutLimits = try container.decodeIfPresent(CheckoutLimits.self, forKey: .checkoutLimits)
        self.messages = try container.decodeIfPresent(ProjectMessages.self, forKey: .messages)

        let paymentMethods = try container.decodeIfPresent([String].self, forKey: .paymentMethods) ?? []
        self.paymentMethods = paymentMethods.compactMap { RawPaymentMethod(rawValue: $0) }
    }

    private init() {
        self.id = "none"
        self.name = ""
        self.links = ProjectLinks.empty
        self.rawLinks = [:]
        self.currency = ""
        self.decimalDigits = 0
        self.locale = ""
        self.roundingMode = .up
        self.qrCodeConfig = nil
        self.currencySymbol = ""
        self.shops = []
        self.scanFormats = []
        self.customerCards = CustomerCardInfo()
        self.codeTemplates = []
        self.searchableTemplates = nil
        self.priceOverrideCodes = nil
        self.checkoutLimits = nil
        self.messages = nil
        self.paymentMethods = []
    }

    // only used for unit tests!
    internal init(_ id: String, links: ProjectLinks) {
        self.id = id
        self.name = ""
        self.links = links
        self.rawLinks = [:]
        self.currency = ""
        self.decimalDigits = 0
        self.locale = ""
        self.roundingMode = .up
        self.qrCodeConfig = nil
        self.currencySymbol = ""
        self.shops = []
        self.scanFormats = []
        self.customerCards = CustomerCardInfo()
        self.codeTemplates = []
        self.searchableTemplates = nil
        self.priceOverrideCodes = nil
        self.checkoutLimits = nil
        self.messages = nil
        self.paymentMethods = []
    }

    static let none = Project()

    // find the currencySymbol for the given currencyCode
    private static func currencySymbol(for currencyCode: String, locale: String) -> String {
        let formatter = NumberFormatter()
        formatter.currencyCode = currencyCode
        formatter.numberStyle = .currency

        // AFAICT there is no API to get the symbol from the code directly, so we need to loop over
        // all available locales to find the first that has a matching code and use its symbol :(
        let allLocales = Locale.availableIdentifiers.lazy.map { Locale(identifier: $0) }
        if let matchingLocale = allLocales.first(where: { $0.currencyCode == currencyCode }) {
            formatter.locale = matchingLocale
        } else {
            formatter.locale = Locale(identifier: locale)
        }

        return formatter.currencySymbol
    }
}

/// Link
public struct Link: Codable {
    public let href: String

    /// empty instance, used for the default init of `MetadataLinks`
    static let empty = Link(href: "")
}

public struct ProjectLinks: Decodable {
    public let appdb: Link
    public let appEvents: Link
    public let checkoutInfo: Link
    public let tokens: Link
    public let resolvedProductBySku: Link?
    public let resolvedProductLookUp: Link?
    public let assetsManifest: Link?

    public static let empty = ProjectLinks()

    private init() {
        self.appdb = Link.empty
        self.appEvents = Link.empty
        self.checkoutInfo = Link.empty
        self.tokens = Link.empty

        self.resolvedProductBySku = nil
        self.resolvedProductLookUp = nil
        self.assetsManifest = nil
    }

    init(appdb: Link, appEvents: Link, checkoutInfo: Link, tokens: Link, resolvedProductBySku: Link, resolvedProductLookUp: Link) {
        self.appdb = appdb
        self.appEvents = appEvents
        self.checkoutInfo = checkoutInfo
        self.tokens = tokens
        self.resolvedProductBySku = resolvedProductBySku
        self.resolvedProductLookUp = resolvedProductLookUp

        self.assetsManifest = nil
    }
}

public struct Flags: Decodable {
    public let kill: Bool
    private let data: [String: Any]

    public subscript(_ key: String) -> Any? {
        return self.data[key]
    }

    private enum CodingKeys: String, CodingKey {
        case kill
    }

    private struct AdditionalCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.kill = try keyedContainer.decode(Bool.self, forKey: .kill)

        let dataContainer = try decoder.container(keyedBy: AdditionalCodingKeys.self)
        self.data = try dataContainer.decode([String: Any].self)
    }

    fileprivate init() {
        self.kill = false
        self.data = [:]
    }
}

public enum RoundingMode: String, Codable, UnknownCaseRepresentable {
    /// always round up
    case up
    /// always round down
    case down
    /// round to the closest possible value; when caught halfway between two positive numbers, round up; when caught between two negative numbers, round down.
    /// (ie use `NSDecimalNumber.RoundingMode.plain`)
    case commercial

    /// get the appropriate `NSDecimalNumber.RoundingMode`
    var mode: NSDecimalNumber.RoundingMode {
        switch self {
        case .up: return .up
        case .down: return .down
        case .commercial: return .plain
        }
    }

    public static let unknownCase = RoundingMode.up
}

// MARK: - shop data

/// opening hours
public struct OpeningHoursSpecification: Codable {
    public let opens: String
    public let closes: String
    public let dayOfWeek: String
}

/// base data for one shop
public struct Shop: Codable {
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.project, forKey: .project)
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
    }
}

// MARK: - loading metadata

public extension Metadata {

    static func readResource(_ path: String) -> Metadata? {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let metadata = try JSONDecoder().decode(Metadata.self, from: data)
            return metadata
        } catch let error {
            Log.error("error parsing app data resource: \(error)")
        }
        return nil
    }

    static func load(from url: String, completion: @escaping (Metadata?) -> Void ) {
        let project = Project.none
        project.request(.get, url, jwtRequired: false, timeout: 5) { request in
            guard var request = request, let absoluteString = request.url?.absoluteString else {
                return completion(nil)
            }

            if SnabbleAPI.debugMode {
                request.cachePolicy = .reloadIgnoringCacheData
            }

            project.performRaw(request) { (result: RawResult<Metadata, SnabbleError>) in
                let hash = absoluteString.djb2hash
                switch result.result {
                case .success(let metadata):
                    completion(metadata)
                    if let raw = result.rawJson {
                        self.saveLastMetadata(raw, hash)
                    }
                case .failure:
                    if let metadata = self.readLastMetadata(url, hash) {
                        completion(metadata)
                    }
                    completion(nil)
                }
            }
        }
    }
}

extension Metadata {
    private static func readLastMetadata(_ url: String, _ hash: Int) -> Metadata? {
        do {
            let fileUrl = try self.urlForLastMetadata(hash)
            let data = try Data(contentsOf: fileUrl)
            let metadata = try JSONDecoder().decode(Metadata.self, from: data)
            // make sure the self link matches
            if url.contains(metadata.links.`self`.href) {
                return metadata
            }
        } catch {
            Log.error("error reading last known metadata: \(error)")
        }
        return nil
    }

    private static func saveLastMetadata(_ raw: [String: Any], _ hash: Int) {
        do {
            let data = try JSONSerialization.data(withJSONObject: raw, options: .fragmentsAllowed)
            let fileUrl = try self.urlForLastMetadata(hash)
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            Log.error("error writing last known metadata: \(error)")
        }
    }

    private static func urlForLastMetadata(_ hash: Int) throws -> URL {
        let fileManager = FileManager.default
        var appSupportDir = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        appSupportDir.appendPathComponent("appmetadata\(hash).json")
        return appSupportDir
    }
}
