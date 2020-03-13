//
//  SnabbleAPI.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import KeychainAccess

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
    public var initialSQL: [String]?

    public init(appId: String, baseUrl: String, secret: String, appVersion: String? = nil, useFTS: Bool = false,
                seedDatabase: String? = nil, seedRevision: Int64? = nil, seedMetadata: String? = nil) {
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

public enum SnabbleAPI {
    public private(set) static var config = SnabbleAPIConfig.none
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

    public static func setup(_ config: SnabbleAPIConfig, completion: @escaping () -> Void ) {
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

    public static func loadMetadata(completion: @escaping () -> Void ) {
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

    public static func getToken(for project: Project, completion: @escaping (String?) -> Void ) {
        self.tokenRegistry.getToken(for: project, completion: completion)
    }

    public static func productProvider(for project: Project) -> ProductProvider {
        assert(!project.id.isEmpty && project.id != Project.none.id, "empty projects don't have a product provider")
        if let provider = providerPool[project.id] {
            return provider
        } else {
            let provider = ProductDB(SnabbleAPI.config, project)
            providerPool[project.id] = provider
            return provider
        }
    }

    public static func removeDatabase(for project: Project) {
        let provider = productProvider(for: project)
        provider.removeDatabase()
        providerPool[project.id] = nil
    }
}

extension SnabbleAPI {
    private static let service = "io.snabble.sdk"
    private static let idKey = "Snabble.api.clientId"
    private static let appUserKey = "Snabble.api.appUserId"

    public static var clientId: String {
        let keychain = Keychain(service: service)

        if let id = keychain[idKey] {
            return id
        }

        if let id = UserDefaults.standard.string(forKey: idKey) {
            keychain[idKey] = id
            return id
        }

        let id = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
        keychain[idKey] = id
        UserDefaults.standard.set(id, forKey: idKey)
        return id
    }

    public static var appUser: String? {
        get {
            let keychain = Keychain(service: service)
            return keychain[appUserKey]
        }

        set {
            let keychain = Keychain(service: service)
            keychain[appUserKey] = newValue

            self.tokenRegistry.invalidateAllTokens()
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
        let queryItems = parameters?.map { (key, value) in
            URLQueryItem(name: key, value: value)
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

extension SnabbleAPI {
    static var debugMode: Bool {
        return _isDebugAssertConfiguration()
    }
}

extension SnabbleAPI {
    static var serverName: String {
        switch config.baseUrl {
        case "https://api.snabble.io":
            return "prod"
        case "https://api.snabble-staging.io":
            return "staging"
        case "https://api.snabble-testing.io":
            return "testing"
        default:
            if SnabbleAPI.debugMode {
                fatalError("API config not correctly initialized")
            }
            return "prod"
        }
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
    public static func getTelecashSecret(_ project: Project, completion: @escaping (Result<TelecashSecret, SnabbleError>) -> Void ) {
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

// MARK: - networking stuff
extension SnabbleAPI {
    static func request(url: URL, timeout: TimeInterval = 0, json: Bool = true) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue(SnabbleAPI.clientId, forHTTPHeaderField: "Client-Id")

        if let userAgent = SnabbleAPI.userAgent {
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        if timeout > 0 {
            request.timeoutInterval = timeout
        }

        if json {
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private static let userAgent: String? = {
        guard
            let bundleDict = Bundle.main.infoDictionary,
            let appName = bundleDict["CFBundleName"] as? String,
            let appVersion = bundleDict["CFBundleShortVersionString"] as? String,
            let appBuild = bundleDict["CFBundleVersion"] as? String
        else {
            return nil
        }

        let appDescriptor = appName + "/" + appVersion + "(" + appBuild + ")"

        let osDescriptor = "iOS/" + UIDevice.current.systemVersion

        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let hardwareString = String(cString: machine)

        return appDescriptor + " " + osDescriptor + " (" + hardwareString + ") SDK/\(APIVersion.version)"
    }()
}
