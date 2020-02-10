//
//  SnabbleAPI.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

/// general config data for using the snabble API.
/// Applications must call `SnabbleAPI.setup()` with an instance of this struct before they make their first API call.
public struct SnabbleAPIConfig {
    /// the appID assigned by snabble
    public let appId: String
    /// the base URL to use
    public let baseUrl: String
    /// the secrect assigned by snabble, used to retrieve authorization tokens
    public let secret: String

    /// the app version that is passed to the metadata endpoint. if not set, the app's `CFBundleShortVersionString` is used
    public let appVersion: String?

    /// set this to true if you want to use the `productsByName` method of `ProductDB`
    public var useFTS = false

    /// if the app comes with a zipped seed database, set this to the path in the Bundle
    public var seedDatabase: String?
    /// if the app comes with a zipped seed database, set this to the db revision of the seed
    public var seedRevision: Int64?
    /// if the app comes with a seed metadata JSON, set this to the path in the Bundle
    public var seedMetadata: String?

    /// max age for the local product database. if the last update of the db is older than this,
    /// the asychronous lookup methods will not use the local database anymore.
    public var maxProductDatabaseAge: TimeInterval = 3600

    // debug mode only:
    // SQL statements that are executed just before the product database is opened
    public var initialSQL: [String]? = nil

    public init(appId: String, baseUrl: String, secret: String, appVersion: String? = nil, useFTS: Bool = false, seedDatabase: String? = nil, seedRevision: Int64? = nil, seedMetadata: String? = nil) {
        self.appId = appId
        self.baseUrl = baseUrl
        self.secret = secret
        self.appVersion = appVersion
        self.useFTS = useFTS
        self.seedDatabase = seedDatabase
        self.seedRevision = seedRevision
        self.seedMetadata = seedMetadata
    }

    static let none = SnabbleAPIConfig(appId: "none", baseUrl: "", secret: "")
}

public struct SnabbleAPI {
    private(set) public static var config = SnabbleAPIConfig.none
    static var tokenRegistry = TokenRegistry("", "")
    static var metadata = Metadata.none

    private static var providerPool = [String: ProductProvider]()

    public static var certificates: [GatewayCertificate] {
        return self.metadata.gatewayCertificates
    }
    
    public static var projects: [Project] {
        return self.metadata.projects
    }

    public static var flags: Flags {
        return self.metadata.flags
    }

    public static var links: MetadataLinks {
        return self.metadata.links
    }

    public static func projectFor(_ projectId: String) -> Project? {
        return self.metadata.projects.first { $0.id == projectId }
    }

    public static func setup(_ config: SnabbleAPIConfig, completion: @escaping ()->() ) {
        self.config = config
        self.initializeTrustKit()

        self.providerPool.removeAll()
        self.tokenRegistry = TokenRegistry(config.appId, config.secret)

        if let metadataPath = config.seedMetadata, self.metadata.projects[0].id == Project.none.id {
            if let metadata = Metadata.readResource(metadataPath) {
                self.setMetadata(metadata)
            }
        }

        self.loadMetadata(completion: completion)
    }

    public static func loadMetadata(completion: @escaping ()->() ) {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let appVersion = config.appVersion ?? bundleVersion
        let version = appVersion.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? appVersion
        let metadataURL = config.baseUrl + "/metadata/app/\(config.appId)/ios/\(version)"

        Metadata.load(from: metadataURL) { metadata in
            if let metadata = metadata {
                self.setMetadata(metadata)
            }
            completion()
        }
    }

    private static func setMetadata(_ metadata: Metadata) {
        self.metadata = metadata

        for project in metadata.projects {
            project.codeTemplates.forEach {
                CodeMatcher.addTemplate(project.id, $0.id, $0.template)
            }

            project.priceOverrideCodes?.forEach {
                CodeMatcher.addTemplate(project.id, $0.id, $0.template)
            }
        }
    }

    public static func getToken(for project: Project, completion: @escaping (String?)->() ) {
        self.tokenRegistry.getToken(for: project, completion: completion)
    }

    public static func productProvider(for project: Project) -> ProductProvider {
        assert(project.id != "", "empty projects don't have a product provider")
        if let provider = providerPool[project.id] {
            return provider
        } else {
            let provider = ProductDB(SnabbleAPI.config, project)
            providerPool[project.id] = provider
            return provider
        }
    }
}

extension SnabbleAPI {
    private static let service = "io.snabble.sdk"
    private static let key = "Snabble.api.clientId"

    public static var clientId: String {
        var keychain = Keychain(service: service)

        if let id = keychain[key] {
            return id
        }

        if let id = UserDefaults.standard.string(forKey: key) {
            keychain[key] = id
            return id
        }

        let id = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
        keychain[key] = id
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}

extension SnabbleAPI {
    static func urlFor(_ url: String) -> URL? {
        return URL(string: self.absoluteUrl(url))
    }

    private static func absoluteUrl(_ url: String) -> String {
        if url.hasPrefix("/") {
            return self.config.baseUrl + url
        } else {
            return url
        }
    }

    static func urlString(_ url: String, _ parameters: [String: String]?) -> String? {
        let queryItems = parameters?.map { (k, v) in
            URLQueryItem(name: k, value: v)
        }
        return urlString(url, queryItems ?? [])
    }

    static func urlString(_ url: String, _ queryItems: [URLQueryItem]) -> String? {
        guard var urlComponents = URLComponents(string: url) else {
            return nil
        }
        if urlComponents.queryItems == nil {
            urlComponents.queryItems = queryItems
        } else {
            urlComponents.queryItems?.append(contentsOf: queryItems)
        }

        return urlComponents.url?.absoluteString
    }
}

// MARK: - telecash

public struct TelecashSecret: Decodable {
    public let hash: String
    public let storeId: String
    public let date: String
    public let currency: String
    public let chargeTotal: String
    public let url: String
}

extension SnabbleAPI {
    public static func getTelecashSecret(_ project: Project, completion: @escaping (Result<TelecashSecret, SnabbleError>)->() ) {
        project.request(.get, SnabbleAPI.metadata.links.telecashSecret.href, timeout: 5) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            project.perform(request) { (_ result: Result<TelecashSecret, SnabbleError>) in
                completion(result)
            }
        }
    }

    public static func deletePreauth(_ project: Project, _ orderId: String) {
        let url = SnabbleAPI.metadata.links.telecashPreauth.href
                    .replacingOccurrences(of: "{orderID}", with: orderId)
        
        project.request(.delete, url, timeout: 5) { request in
            guard let request = request else {
                return
            }

            struct DeleteResponse: Decodable {}
            project.perform(request) { (_ result: Result<DeleteResponse, SnabbleError>) in
                print(result)
            }
        }
    }
}
