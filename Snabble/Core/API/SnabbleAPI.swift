//
//  SnabbleAPI.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import KeychainAccess

/// General config data for using the snabble API.
/// Applications must call `SnabbleAPI.setup()` with an instance of this struct before they make their first API call.
public struct SnabbleAPIConfig {
    /// the appID assigned by snabble
    public let appId: String
    /// the environment  to use
    public let environment: SnabbleAPI.Environment
    /// the secrect assigned by snabble, used to retrieve authorization tokens
    public let secret: String

    /// the app version that is passed to the metadata endpoint. if not set, the app's `CFBundleShortVersionString` is used
    public var appVersion: String?

    /// set this to true if you want to use the `productsByName` method of `ProductDB`
    /// this flag is ignored for projects that have a `shoppingListDB` link
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

    /// load shop list from the `activeShops` endpoint?
    public var loadActiveShops = false

    // debug mode only:
    // SQL statements that are executed just before the product database is opened
    public var initialSQL: [String]?

    /// Initialize the configuration for Snabble
    /// - Parameters:
    ///   - appId: Provide your personal `appId`
    ///   - secret: The secret matching your `appId`
    ///   - environment: Choose an environment you want to use
    public init(appId: String, secret: String, environment: SnabbleAPI.Environment = .production) {
        self.appId = appId
        self.environment = environment
        self.secret = secret
    }

    static let none = SnabbleAPIConfig(appId: "none", secret: "")
}

public extension Notification.Name {
    static var metadataLoaded = Notification.Name(rawValue: "io.snabble.metadataLoaded")
}

/**
 * The main entry point for the SnabbleSDK.
 *
 * Use `SnabbleAPI.setup(_:, completion:)` to initialize Snabble.
 */
public enum SnabbleAPI {

    /**
     * Environment in which the SDK should work
     *
     * Possible values are `testing`, `staging` and `production`.
     * `production` is the default in the sdk
     */
    public enum Environment: String, CaseIterable, Equatable {
        case testing
        case staging
        case production

        public var urlString: String {
            switch self {
            case .testing:
                return "https://api.snabble-testing.io"
            case .staging:
                return "https://api.snabble-staging.io"
            case .production:
                return "https://api.snabble.io"
            }
        }

        public var name: String {
            switch self {
            case .testing, .staging:
                return rawValue
            case .production:
                return "prod"
            }
        }
    }

    private(set) static var config = SnabbleAPIConfig.none
    private(set) static var tokenRegistry = TokenRegistry(appId: "", secret: "")

    static var metadata = Metadata.none {
        didSet {
            for project in metadata.projects {
                project.codeTemplates.forEach {
                    CodeMatcher.addTemplate(project.id, $0.id, $0.template)
                }

                project.priceOverrideCodes?.forEach {
                    CodeMatcher.addTemplate(project.id, $0.id, $0.template)
                }
            }

            NotificationCenter.default.post(name: .metadataLoaded, object: nil)
        }
    }
    static let methodRegistry = MethodRegistry()

    private static var providerPool = [Identifier<Project>: ProductProvider]()

    /// Gateway certificates for payment routes
    static var certificates: [GatewayCertificate] {
        return self.metadata.gatewayCertificates
    }

    /// Available projects after a successful setup
    public static var projects: [Project] {
        return self.metadata.projects
    }

    /// Additional information provided by Snabble
    public static var flags: Flags {
        return self.metadata.flags
    }

    /// API links for snabble features
    public static var links: MetadataLinks {
        return self.metadata.links
    }

    /// Terms of Use for the Snabble App
    public static var terms: Terms? {
        return self.metadata.terms
    }

    /// Are used to combine multiple projects
    public static var brands: [Brand] {
        return self.metadata.brands ?? []
    }

    /// Finds project for a given id
    /// - Parameter projectId: matching id
    /// - Returns: `Project` or `nil` if none was found
    public static func project(for projectId: Identifier<Project>) -> Project? {
        return self.metadata.projects.first { $0.id == projectId }
    }

    /// First method to be called to initialize of the `SnabbleSDK`
    /// - Parameters:
    ///   - config: `SnabbleAPIConfig` with at least an `appId` and a `secret`
    ///   - completion: CompletionHandler is called as soon as everything is finished
    public static func setup(config: SnabbleAPIConfig, completion: @escaping () -> Void ) {
        self.config = config
        self.config.useCertificatePinning = !self.debugMode || config.useCertificatePinning

        if self.config.useCertificatePinning {
            self.initializeTrustKit()
        }

        self.providerPool.removeAll()
        self.tokenRegistry = TokenRegistry(appId: config.appId, secret: config.secret)

        if let metadataPath = config.seedMetadata, self.metadata.projects.isEmpty {
            if let metadata = Metadata.readResource(metadataPath) {
                self.metadata = metadata
            }
        }

        self.update(completion: completion)
    }

    /// update Snabble
    /// - Parameter completion: completionHandler informs about the status
    public static func update(completion: @escaping () -> Void ) {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let appVersion = config.appVersion ?? bundleVersion
        let version = appVersion.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? appVersion
        let metadataURL = "/metadata/app/\(config.appId)/ios/\(version)"

        Metadata.load(from: metadataURL) { metadata in
            if let metadata = metadata {
                self.metadata = metadata
            }

            let metadataLoaded = {
                if self.config.loadActiveShops {
                    self.loadActiveShops()
                }
                self.loadCoupons {
                    completion()
                }
            }

            if let project = self.metadata.projects.first {
                self.tokenRegistry.getToken(for: project) { _ in
                    metadataLoaded()
                }
            } else {
                metadataLoaded()
            }
        }
    }

    private static func loadActiveShops() {
        // reload shops from `activeShops` endpoint where present
        for (index, project) in metadata.projects.enumerated() {
            guard let activeShops = project.links.activeShops?.href else {
                continue
            }

            project.request(.get, activeShops, timeout: 3) { request in
                guard let request = request else {
                    return
                }

                project.perform(request) { (result: Result<ActiveShops, SnabbleError>) in
                    switch result {
                    case .success(let activeShops):
                        self.metadata.setShops(activeShops.shops, at: index)
                    case .failure(let error):
                        print("\(#function), \(project.id) \(error)")
                    }
                }
            }
        }
    }

    private static func loadCoupons(_ completion: @escaping () -> Void) {
        // reload coupons from `coupons` endpoint where present
        let group = DispatchGroup()

        for (index, project) in metadata.projects.enumerated() {
            guard let coupons = project.links.coupons?.href else {
                continue
            }

            group.enter()
            project.request(.get, coupons, timeout: 3) { request in
                guard let request = request else {
                    group.leave()
                    return
                }

                project.perform(request) { (result: Result<CouponList, SnabbleError>) in
                    group.leave()
                    switch result {
                    case .success(let couponList):
                        self.metadata.setCoupons(couponList.coupons, at: index)
                    case .failure(let error):
                        print("\(#function), \(error)")
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion()
        }
    }

    /// Product Provider for a project
    /// - Parameter project: `Project` associated to the product provider
    /// - Returns: `ProductProvider` to retrieve products
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

    /// Removes database for a project
    ///
    ///  Restart the app after removing a database
    /// - Warning: For debugging only
    /// - Parameter project: `Project` of the database to be deleted
    public static func removeDatabase(of project: Project) {
        let provider = productProvider(for: project)
        provider.removeDatabase()
        providerPool[project.id] = nil
    }
}

/// SnabbleSDK application user identification
public struct AppUserId {
    /// the actual information of the `userId`
    public let value: String

    /// an opaque information for the backend
    public let secret: String

    /// `value` and `secret` combined in a `String` separated by a colon
    public var combined: String {
        "\(value):\(secret)"
    }

    /// initialize an `AppUserId` with a received `value` and `secret`
    /// - Parameters:
    ///   - value: the actual information of the `userId`
    ///   - secret: an opaque information for the backend
    public init(value: String, secret: String) {
        self.value = value
        self.secret = secret
    }

    /// An optional initializer.
    ///
    /// `value` and `secret` must be separated by a colon.
    public init?(_ string: String?) {
        guard
            let components = string?.split(separator: ":"),
            components.count == 2
        else {
            return nil
        }

        value = String(components[0])
        secret = String(components[1])
    }
}

extension SnabbleAPI {
    private static let service = "io.snabble.sdk"

    // MARK: - client id
    private static let idKey = "Snabble.api.clientId"

    /**
     SnabbleSDK client identification

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
    */
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
        return "Snabble.api.appUserId.\(config.environment.name).\(SnabbleAPI.config.appId)"
    }

    /**
     SnabbleSDK application user identification

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
    */
    public static var appUserId: AppUserId? {
        get {
            let keychain = Keychain(service: service)
            return AppUserId(keychain[appUserKey])
        }

        set {
            let keychain = Keychain(service: service)
            keychain[appUserKey] = newValue?.combined
            UserDefaults.standard.set(newValue?.value, forKey: "Snabble.api.appUserId")

            tokenRegistry.invalidateAllTokens()
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
            return self.config.environment.urlString + url
        } else {
            return url
        }
    }

    static func urlString(_ url: String, _ parameters: [String: String]?) -> String? {
        let queryItems = parameters?.map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        return urlString(url, queryItems)
    }

    static func urlString(_ url: String, _ queryItems: [URLQueryItem]?) -> String? {
        guard var urlComponents = URLComponents(string: url) else {
            return nil
        }
        if let queryItems = queryItems, !queryItems.isEmpty {
            if urlComponents.queryItems == nil {
                urlComponents.queryItems = queryItems
            } else {
                urlComponents.queryItems?.append(contentsOf: queryItems)
            }
        }

        return urlComponents.url?.absoluteString
    }
}

extension SnabbleAPI {
    static var debugMode: Bool {
        return _isDebugAssertConfiguration()
    }
}

// MARK: - networking stuff
extension SnabbleAPI {
    public static func request(url: URL, timeout: TimeInterval? = nil, json: Bool = true) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue(SnabbleAPI.clientId, forHTTPHeaderField: "Client-Id")

        if let userAgent = SnabbleAPI.userAgent {
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        if let timeout = timeout {
            request.timeoutInterval = timeout
        }

        if json {
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let acceptLanguage = Bundle.main.preferredLocalizations.enumerated()
            .map { index, language in
                let quality = max(9 - index, 1)
                return "\(language);q=0.\(quality)"
            }
            .joined(separator: ",")
        request.addValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")

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

    private(set) static var appUserData: AppUserData?
    private static weak var appUserDataTask: URLSessionDataTask?

    static func fetchAppUserData(_ projectId: Identifier<Project>) {
        guard
            appUserDataTask == nil,
            let project = SnabbleAPI.project(for: projectId),
            let appUserId = SnabbleAPI.appUserId
        else {
            return
        }

        let url = SnabbleAPI.links.appUser.href.replacingOccurrences(of: "{appUserID}", with: appUserId.value)
        project.request(.get, url, timeout: 2) { request in
            guard let request = request else {
                return
            }

            appUserDataTask = project.perform(request) { (result: Result<AppUserData, SnabbleError>) in
                switch result {
                case .success(let userData):
                    SnabbleAPI.appUserData = userData
                case .failure(let error):
                    print("\(#function), \(error)")
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
            let consents = SnabbleAPI.links.consents?.href,
            let project = SnabbleAPI.projects.first
        else {
            return
        }

        let url = consents.replacingOccurrences(of: "{appUserID}", with: appUserId.value)

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
                    // ignore "client error" since we can't recover from it
                    completion(error == SnabbleError.empty || error.type == .clientError)
                }
            }
        }
    }
}
