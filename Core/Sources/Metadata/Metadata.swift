//
//  Metadata.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

public struct Metadata: Decodable, @unchecked Sendable {
    public let flags: Flags
    public private(set) var projects: [Project]
    public let gatewayCertificates: [GatewayCertificate]
    public let links: MetadataLinks
    public let terms: Terms?
    public let brands: [Brand]

    enum CodingKeys: String, CodingKey {
        case flags = "metadata"
        case projects, gatewayCertificates, links, templates, terms, brands
    }

    private init() {
        self.flags = Flags()
        self.projects = []
        self.gatewayCertificates = []
        self.links = MetadataLinks()
        self.terms = nil
        self.brands = []
    }

    static let none = Metadata()

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.flags = try container.decode(Flags.self, forKey: .flags)
        self.projects = try container.decode([Project].self, forKey: .projects)
        let certs = try container.decodeIfPresent([GatewayCertificate].self, forKey: .gatewayCertificates)
        self.gatewayCertificates = certs ?? []
        self.links = try container.decode(MetadataLinks.self, forKey: .links)
        self.terms = try container.decodeIfPresent(Terms.self, forKey: .terms)
        self.brands = try container.decodeIfPresent([Brand].self, forKey: .brands) ?? []
    }

    mutating func setShops(_ shops: [Shop], for project: Project) {
        if let index = projects.firstIndex(where: { project == $0 }) {
            projects[index].setShops(shops)
        }
    }

    mutating func setCoupons(_ coupons: [Coupon], for project: Project) {
        if let index = projects.firstIndex(where: { project == $0 }) {
            projects[index].setCoupons(coupons)
        }
    }
}

public struct Brand: Decodable, Identifiable {
    public let id: Identifier<Brand>
    public let name: String
}

public struct Terms: Decodable {
    public let updatedAt: String
    public let version: String
    public let variants: [TermVariant]

    public struct TermVariant: Decodable {
        public let isDefault: Bool?
        public let language: String
        public let links: TermVariantLink
    }

    public struct TermVariantLink: Decodable {
        public let content: Link
    }
}

public struct GatewayCertificate: Decodable {
    public let value: String
    public let validUntil: String // iso8601 date

    public var data: Data? {
        return Data(base64Encoded: self.value, options: .ignoreUnknownCharacters)
    }
}

public struct MetadataLinks: Decodable {
    public let clientOrders: Link?
    public let appUser: Link
    public let appUserOrders: Link
    public let chargingFeatureEnabled: Link?
    public let consents: Link?
    public let giropayCustomerAuthorization: Link?
    public let createAppUser: Link
    public let _self: Link

    enum CodingKeys: String, CodingKey {
        case _self = "self"
        case clientOrders, appUser, appUserOrders, chargingFeatureEnabled, consents, createAppUser
        case giropayCustomerAuthorization = "paydirektCustomerAuthorization"
    }

    fileprivate init() {
        self.clientOrders = nil
        self.appUser = Link.empty
        self.appUserOrders = Link.empty
        self.createAppUser = Link.empty
        self._self = Link.empty

        self.chargingFeatureEnabled = Link.empty
        self.consents = Link.empty
        self.giropayCustomerAuthorization = nil
    }
}

public struct Flags: Decodable {
    public let kill: Bool
    public let cortexDecoderCustomerID: String?
    public let cortexDecoderLicenseKey: String?

    private let data: [String: Any]

    public subscript(_ key: String) -> Any? {
        return self.data[key]
    }

    private enum CodingKeys: String, CodingKey {
        case kill
        case cortexDecoderCustomerID
        case cortexDecoderLicenseKey
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
        self.cortexDecoderCustomerID = try keyedContainer.decodeIfPresent(String.self, forKey: .cortexDecoderCustomerID)
        self.cortexDecoderLicenseKey = try keyedContainer.decodeIfPresent(String.self, forKey: .cortexDecoderLicenseKey)

        let dataContainer = try decoder.container(keyedBy: AdditionalCodingKeys.self)
        self.data = try dataContainer.decode([String: Any].self)
    }

    fileprivate init() {
        self.kill = false
        self.cortexDecoderCustomerID = nil
        self.cortexDecoderLicenseKey = nil
        self.data = [:]
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

    static func load(from url: String, completion: @escaping @Sendable (Metadata?) -> Void ) {
        let project = Project.none
        project.request(.get, url, jwtRequired: false, timeout: 5) { request in
            guard var request = request, let absoluteString = request.url?.absoluteString else {
                return completion(nil)
            }

            if Snabble.debugMode {
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
                    let metadata = self.readLastMetadata(url, hash)
                    completion(metadata)
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
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .customISO8601
            let metadata = try decoder.decode(Metadata.self, from: data)
            // make sure the self link matches
            if url.contains(metadata.links._self.href) {
                return metadata
            }
        } catch {
            Log.error("error reading last known metadata: \(error)")
        }
        return nil
    }

    private static func saveLastMetadata(_ raw: [String: Any], _ hash: Int) {
        do {
            removePreviousMetadataFiles()
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

    private static func removePreviousMetadataFiles() {
        do {
            let fileManager = FileManager.default
            let appSupportDir = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            let files = try fileManager.contentsOfDirectory(atPath: appSupportDir.path)
            for file in files {
                if file.hasPrefix("appmetadata") && file.hasSuffix(".json") {
                    let url = appSupportDir.appendingPathComponent(file)
                    try fileManager.removeItem(at: url)
                }
            }
        } catch {
            Log.error("error removing old metadata files: \(error)")
        }
    }
}
