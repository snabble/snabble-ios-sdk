//
//  Snabble.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import KeychainAccess
import CoreLocation

/// General config data for using the snabble.
/// Applications must call `Snabble.setup(config: completion:)` with an instance of this struct before they make their first API call.
public struct Config {
    /// the appID assigned by snabble
    public let appId: String
    /// the environment  to use
    public let environment: Snabble.Environment
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
    public init(appId: String, secret: String, environment: Snabble.Environment = .production) {
        self.appId = appId
        self.environment = environment
        self.secret = secret
    }
}

public extension Notification.Name {
    static var metadataLoaded = Notification.Name(rawValue: "io.snabble.metadataLoaded")
}

/**
 * The main entry point for the SnabbleSDK.
 *
 * Use `Snabble.setup(config:, completion:)` to initialize Snabble.
 */
public class Snabble {

    private init(config: Config, tokenRegistry: TokenRegistry) {
        self.config = config
        self.tokenRegistry = tokenRegistry
        self.databases = [:]

        if let metadataPath = config.seedMetadata {
            if let metadata = Metadata.readResource(metadataPath) {
                self.metadata = metadata
            }
        }
    }
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

        /// Verification for the `appId`
        ///
        /// The secret and `appId` can only be used for demo cases
        public var secret: String {
            switch self {
            case .testing:
                return "BWXJ2BFC2JRKRNW4QBASQCF2TTANPTVPOXQJM57JDIECZJQHZWOQ===="
            case .staging:
                return "P3SZXAPPVAZA5JWYXVKFSGGBN4ZV7CKCWJPQDMXSUMNPZ5IPB6NQ===="
            case .production:
                return "2TKKEG5KXWY6DFOGTZKDUIBTNIRVCYKFZBY32FFRUUWIUAFEIBHQ===="
            }
        }
    }

    /// Snabble instance is accessible after calling `Snabble.setup(config:, completion:)`
    public private(set) static var shared: Snabble!

    /// Geo-fencing based check in manager. Use for automatically detecting if you are in a shop.
    public lazy var checkInManager = CheckInManager()

    public lazy var couponManager = CouponManager()

    public lazy var shoppingCartManager = ShoppingCartManager()

    /// Will be set with setup(config:, completion:)
    let config: Config

    /// Will be created in setup(config:, completion:)
    let tokenRegistry: TokenRegistry

    private(set) var metadata = Metadata.none {
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
    public var paydirektAuthorizationHref: String? {
        return metadata.links.paydirektCustomerAuthorization?.href
    }
    public static let methodRegistry = MethodRegistry()

    private var databases: [Identifier<Project>: ProductDatabase]

    /// Current environment
    public var environment: Environment {
        return self.config.environment
    }

    /// Gateway certificates for payment routes
    public var certificates: [GatewayCertificate] {
        metadata.gatewayCertificates
    }

    /// Available projects after a successful setup
    public var projects: [Project] {
        metadata.projects
    }

    /// Additional information provided by Snabble
    public var flags: Flags {
        metadata.flags
    }

    /// API links for snabble features
    public var links: MetadataLinks {
        metadata.links
    }

    /// Terms of Use for the Snabble App
    public var terms: Terms? {
        metadata.terms
    }

    /// Are used to combine multiple projects
    public var brands: [Brand] {
        metadata.brands
    }

    /// Finds project for a given id
    /// - Parameter projectId: matching id
    /// - Returns: `Project` or `nil` if none was found
    public func project(for projectId: Identifier<Project>) -> Project? {
        metadata.projects.first { $0.id == projectId }
    }

    /// First method to be called to initialize of the `SnabbleSDK`
    /// - Parameters:
    ///   - config: `SnabbleAPIConfig` with at least an `appId` and a `secret`
    ///   - completion: CompletionHandler is called as soon as everything is finished
    public static func setup(config: Config, completion: @escaping (Snabble) -> Void) {
        if config.useCertificatePinning {
            initializeTrustKit()
        }

        shared = Snabble(
            config: config,
            tokenRegistry: TokenRegistry(appId: config.appId, secret: config.secret)
        )
        shared?.update(completion: completion)
    }
    
    /// update Snabble
    /// - Parameter completion: completionHandler informs about the status
    public func update(completion: @escaping (Snabble) -> Void) {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let appVersion = config.appVersion ?? bundleVersion
        let version = appVersion.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? appVersion
        let metadataURL = "/metadata/app/\(config.appId)/ios/\(version)"

        Metadata.load(from: metadataURL) { [self] metadata in
            if let metadata = metadata {
                self.metadata = metadata
            }

            let metadataLoaded = {
                if self.config.loadActiveShops {
                    self.loadActiveShops()
                }
                self.loadCoupons {
                    completion(self)
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

    private func loadActiveShops() {
        // reload shops from `activeShops` endpoint where present
        for project in metadata.projects {
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
                        self.metadata.setShops(activeShops.shops, for: project)
                    case .failure(let error):
                        print("\(#function), \(project.id) \(error)")
                    }
                }
            }
        }
    }

    private func loadCoupons(_ completion: @escaping () -> Void) {
        // reload coupons from `coupons` endpoint where present
        let group = DispatchGroup()

        for project in metadata.projects {
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
                        self.metadata.setCoupons(couponList.coupons, for: project)
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
    
    /// Set up database for project
    /// - Parameter project: `Project` associated to setup the product database
    public func setupProductDatabase(for project: Project, completion: @escaping (ProductStoreAvailability) -> Void) {
        productDatabase(for: project).setup(completion: completion)
    }
    
    /// Product Database for a project
    /// - Parameter project: `Project` associated to the product provider
    /// - Returns: `ProductDatabase` the products database
    private func productDatabase(for project: Project) -> ProductDatabase {
        assert(!project.id.rawValue.isEmpty && project.id != Project.none.id, "empty projects don't have a product provider")
        if let database = databases[project.id] {
            return database
        } else {
            let database = ProductDatabase(config, project)
            databases[project.id] = database
            return database
        }
    }

    /// ProductProviding for a project
    /// - Parameter project: `Project` associated to the product provider
    /// - Returns: `ProductProviding` the products database
    public func productProvider(for project: Project) -> ProductProviding {
        productDatabase(for: project)
    }

    /// ProductStore for a project
    /// - Parameter project: `Project` associated to the product provider
    /// - Returns: `ProductStore` the products database
    public func productStore(for project: Project) -> ProductStoring {
        productDatabase(for: project)
    }

    /// Removes database for a project
    ///
    ///  Restart the app after removing a database
    /// - Warning: For debugging only
    /// - Parameter project: `Project` of the database to be deleted
    public func removeDatabase(of project: Project) {
        let productDatabase = productDatabase(for: project)
        productDatabase.removeDatabase()
        databases[project.id] = nil
    }
}

/// SnabbleSDK application user identification
///
/// A plain text username and password combination.
/// - Important: It contains a sensitve data. Be careful when you store it.
public struct AppUserId {
    /// the `userId` of the `AppUserId`
    public let value: String

    /// an opaque information for the backend
    public let secret: String

    /// A formatted string that specifies the components of the `AppUserId`.
    ///
    /// The string representation always has two components separated by a colon. The first is the `value` and last is the `secret`
    public var stringRepresentation: String {
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

    /**
     An optional initializer with a valid `stringRepresentation` value

     `value` and `secret` must be separated by a colon.

     - Precondition:
        - `value` is the first part and `secret` the second.
        - Only two elements allowed after split by colon
     */
    public init?(stringRepresentation: String) {
        let components = stringRepresentation.split(separator: ":")
        guard components.count == 2 else {
            return nil
        }

        value = String(components[0])
        secret = String(components[1])
    }
}

extension Snabble {
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
    private var appUserKey: String {
        "Snabble.api.appUserId.\(config.environment.name).\(config.appId)"
    }

    /**
     SnabbleSDK application user identification

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
    */
    public var appUserId: AppUserId? {
        get {
            let keychain = Keychain(service: Self.service)
            guard let stringRepresentation = keychain[appUserKey] else {
                return nil
            }
            return AppUserId(stringRepresentation: stringRepresentation)
        }

        set {
            let keychain = Keychain(service: Self.service)
            keychain[appUserKey] = newValue?.stringRepresentation
            UserDefaults.standard.set(newValue?.value, forKey: "Snabble.api.appUserId")

            tokenRegistry.invalidateAllTokens()
            OrderList.clearCache()
        }
    }
}

extension Snabble {
    public func urlFor(_ url: String) -> URL? {
        URL(string: absoluteUrl(url))
    }

    private func absoluteUrl(_ url: String) -> String {
        if url.hasPrefix("/") {
            return config.environment.urlString + url
        } else {
            return url
        }
    }
}

extension Snabble {
    public static var debugMode: Bool {
        return _isDebugAssertConfiguration()
    }
}

// MARK: - networking stuff
extension Snabble {
    public static func request(url: URL, timeout: TimeInterval? = nil, json: Bool = true) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue(Snabble.clientId, forHTTPHeaderField: "Client-Id")

        if let userAgent = Snabble.userAgent {
            request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        for (key, value) in headerFields {
            request.addValue(value, forHTTPHeaderField: key)
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

    private static let osDescriptor: (name: String, version: String) = {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

#if os(iOS)
            return ("iOS", versionString)
#elseif os(watchOS)
            return ("watchOS", versionString)
#elseif os(tvOS)
            return ("tvOS", versionString)
#elseif os(macOS)
            return ("macOS", versionString)
#else
            return ("unknown", versionString)
#endif
    }()

    private static let hardwareDescriptor: String = {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        
        return String(cString: machine)
    }()

    private static let headerFields: [String: String] = {
        guard
            let bundleDict = Bundle.main.infoDictionary,
            let appName = bundleDict["CFBundleName"] as? String,
            let appVersion = bundleDict["CFBundleShortVersionString"] as? String,
            let appBuild = bundleDict["CFBundleVersion"] as? String
        else {
            return [:]
        }
        let significantVersion = appVersion.components(separatedBy: ".").first ?? appVersion
        // e.g.: SnabbleSambleApp;v=1
        let brand = "\(appName);v=\(significantVersion)"

        // e.g.: SnabbleSambleApp;v=1.0.1,SDK;v=0.34.1
        let fullVersionList = "\(appName);v=\(appVersion).\(appBuild),SDK;v=\(SDKVersion)"

        return [
            // e.g.: SnabbleSambleApp;v=1
            "Sec-CH-UA": brand,

            // e.g.: SnabbleSambleApp;v=1.0.1,SDK;v=0.34.1
            "Sec-CH-UA-Full-Version-List": fullVersionList,
                        
            // e.g.: iOS
            "Sec-CH-UA-Platform": osDescriptor.name,
            
            // e.g.: 16.5.0
            "Sec-CH-UA-Platform-Version": osDescriptor.version,
                        
            // e.g.: "arm64", "iPhone13,3", ...)
            "Sec-CH-UA-Arch": hardwareDescriptor
        ]
    }()

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
        
        return "\(appDescriptor) \(osDescriptor.name)/\(osDescriptor.version) (\(hardwareDescriptor)) SDK/\(SDKVersion)"
    }()
}

// MARK: - age data
extension Snabble {
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

    public static var userAge: Int {
        return appUserData?.age ?? 0
    }
    
    public func fetchAppUserData(_ projectId: Identifier<Project>) {
        guard
            Self.appUserDataTask == nil,
            let project = project(for: projectId),
            let appUserId = appUserId
        else {
            return
        }

        let url = links.appUser.href.replacingOccurrences(of: "{appUserID}", with: appUserId.value)
        project.request(.get, url, timeout: 2) { request in
            guard let request = request else {
                return
            }

            Self.appUserDataTask = project.perform(request) { (result: Result<AppUserData, SnabbleError>) in
                switch result {
                case .success(let userData):
                    Snabble.appUserData = userData
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

    public func saveTermsConsent(_ version: String, completion: @escaping (Bool) -> Void) {
        guard
            let appUserId = appUserId,
            let consents = links.consents?.href,
            let project = projects.first
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
