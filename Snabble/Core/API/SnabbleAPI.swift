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

    /// set to false to disable certificate pinning for requests to the snabble API server
    /// NOTE: this setting is intended for debugging purposes only and is ignored in Release builds
    public var useCertificatePinning = true

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

    public init(appId: String, baseUrl: String, secret: String, appVersion: String? = nil,
                useFTS: Bool = false, useCertificatePinning: Bool = true,
                seedDatabase: String? = nil, seedRevision: Int64? = nil, seedMetadata: String? = nil) {
        self.appId = appId
        self.baseUrl = baseUrl
        self.secret = secret
        self.appVersion = appVersion
        self.useFTS = useFTS
        self.useCertificatePinning = useCertificatePinning
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

    private static var providerPool = [Identifier<Project>: ProductProvider]()

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

    public static var terms: Terms? {
        return self.metadata.terms
    }

    public static var brands: [Brand] {
        return self.metadata.brands ?? []
    }

    public static func project(for projectId: Identifier<Project>) -> Project? {
        return self.metadata.projects.first { $0.id == projectId }
    }

    public static func setup(_ config: SnabbleAPIConfig, completion: @escaping () -> Void ) {
        self.config = config
        self.config.useCertificatePinning = !self.debugMode || config.useCertificatePinning

        if self.config.useCertificatePinning {
            self.initializeTrustKit()
        }

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
        let metadataURL = "/metadata/app/\(config.appId)/ios/\(version)"

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
        assert(!project.id.rawValue.isEmpty && project.id != Project.none.id, "empty projects don't have a product provider")
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

public struct AppUserId {
    public let userId: String
    let secret: String

    public init(userId: String, secret: String) {
        self.userId = userId
        self.secret = secret
    }

    public init?(_ string: String?) {
        guard
            let components = string?.split(separator: ":"),
            components.count == 2
        else {
            return nil
        }

        self.userId = String(components[0])
        self.secret = String(components[1])
    }

    public var combined: String {
        return "\(self.userId):\(self.secret)"
    }
}

extension SnabbleAPI {
    private static let service = "io.snabble.sdk"

    // MARK: - client id
    private static let idKey = "Snabble.api.clientId"

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

    // MARK: - app user id
    private static var appUserKey: String {
        return "Snabble.api.appUserId.\(SnabbleAPI.serverName).\(SnabbleAPI.config.appId)"
    }

    public static var appUserId: AppUserId? {
        get {
            let keychain = Keychain(service: service)
            return AppUserId(keychain[appUserKey])
        }

        set {
            let keychain = Keychain(service: service)
            keychain[appUserKey] = newValue?.combined
            UserDefaults.standard.set(newValue?.userId, forKey: "Snabble.api.appUserId")

            self.tokenRegistry.invalidateAllTokens()
            OrderList.clearCache()
        }
    }
}

extension SnabbleAPI {
    public static func urlFor(_ url: String) -> URL? {
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
        let osDescriptor = "\(UIDevice.current.systemName)/\(UIDevice.current.systemVersion)"

        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let hardwareString = String(cString: machine)

        return "\(appDescriptor) \(osDescriptor) (\(hardwareString)) SDK/\(APIVersion.version)"
    }()
}

// MARK: - age data
extension SnabbleAPI {

    struct AppUserData: Codable {
        let id: String
        let dayOfBirth: String?
        let bornBeforeOrOn: String?

        var age: Int? {
            guard let birthDate = dayOfBirth ?? bornBeforeOrOn else {
                return nil
            }

            let cal = Calendar(identifier: .gregorian)
            let formatter = DateFormatter()
            formatter.calendar = cal
            formatter.dateFormat = "yyyy/MM/dd"
            formatter.timeZone = TimeZone(identifier: "UTC")

            guard let date = formatter.date(from: birthDate) else {
                return nil
            }

            let today = Date()
            let years = cal.dateComponents([.year], from: date, to: today)

            return years.year
        }
    }

    static var appUserData: AppUserData?

    static func fetchAppUserData(_ projectId: Identifier<Project>) {
        guard
            let project = SnabbleAPI.project(for: projectId),
            let appUserId = SnabbleAPI.appUserId
        else {
            return
        }

        let url = SnabbleAPI.links.appUser.href.replacingOccurrences(of: "{appUserID}", with: appUserId.userId)
        project.request(.get, url, timeout: 2) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (result: Result<AppUserData, SnabbleError>) in
                switch result {
                case .success(let userData):
                    DispatchQueue.main.async {
                        SnabbleAPI.appUserData = userData
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    private struct TermsVersion: Encodable {
        let version: String
    }

    private struct TermsResponse: Decodable {}

    public static func saveTermsConsent(_ version: String, completion: @escaping (Bool) -> Void) {
        guard
            let appUserId = SnabbleAPI.appUserId,
            let consents = SnabbleAPI.links.consents?.href
        else {
            return
        }

        let url = consents.replacingOccurrences(of: "{appUserID}", with: appUserId.userId)

        let project = SnabbleAPI.projects[0]
        let termsVersion = TermsVersion(version: version)
        project.request(.post, url, body: termsVersion) { request in
            guard let request = request else {
                return
            }

            project.perform(request) { (result: Result<TermsResponse, SnabbleError>) in
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    completion(error == SnabbleError.empty)
                }
            }
        }
    }
}
