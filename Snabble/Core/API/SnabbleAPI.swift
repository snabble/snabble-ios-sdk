//
//  SnabbleAPI.swift
//
//  Copyright © 2018 snabble. All rights reserved.
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
    public var appVersion: String?

    /// set this to true if you want to use the `productsByName` method of `ProductDB`
    public var useFTS = false

    /// if the app comes with a zipped seed database, set this to the path in the Bundle
    public var seedDatabase: String?
    /// if the app comes with a zipped seed database, set this to the db revision of the seed
    public var seedRevision: Int64?
    /// if the app comes with a seed metadata JSON, set this to the path in the Bundle
    public var seedMetadata: String?

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
    static var metadata = Metadata.none
    static var tokenRegistry = TokenRegistry("", "")

    public static var certificates: [GatewayCertificate] {
        return self.metadata.gatewayCertificates
    }
    
    public static var projects: [Project] {
        return self.metadata.projects
    }

    public static var flags: Flags {
        return self.metadata.flags
    }

    public static func setup(_ config: SnabbleAPIConfig, completion: @escaping ()->() ) {
        self.config = config

        self.tokenRegistry = TokenRegistry(config.appId, config.secret)

        if let metadataPath = config.seedMetadata, self.metadata.projects[0].id == Project.none.id {
            if let metadata = Metadata.readResource(metadataPath) {
                self.metadata = metadata
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
                self.metadata = metadata
            }
            completion()
        }
    }

    public static func getToken(for project: Project, completion: @escaping (String?)->() ) {
        self.tokenRegistry.getToken(for: project, completion: completion)
    }

    private static var providerPool = [String: ProductProvider]()

    public static func productProvider(for project: Project) -> ProductProvider {
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
    static var clientId: String {
        if let id = UserDefaults.standard.string(forKey: "Snabble.api.clientId") {
            return id
        } else {
            let id = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
            UserDefaults.standard.set(id, forKey: "Snabble.api.clientId")
            return id
        }
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

/// run `closure` synchronized using `lock`
func synchronized<T>(_ lock: Any, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}
