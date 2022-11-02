//
//  ProductDB.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import GRDB
import Zip
#warning("ProductDB.swift: remove UIKit dependency from SnabbleCore")
import UIKit

/// keys of well-known entries in the metadata table
public enum MetadataKeys {
    public static let revision = "revision"
    public static let schemaVersionMajor = "schemaVersionMajor"
    public static let schemaVersionMinor = "schemaVersionMinor"
    public static let defaultAvailability = "defaultAvailability"

    fileprivate static let appLastUpdate = "app_lastUpdate"
}

/// the return type from `productByScannableCodes`
public struct ScannedProduct {
    /// contains the product found
    public let product: Product
    /// can be used to override the code that gets sent to the backend, e.g. when an EAN-8 is scanned, but the backend requires EAN-13s
    public let transmissionCode: String?
    /// the template that was used to match this code, if any
    public let templateId: String?
    /// the template we should use to generate the QR code, if not same as `templateId`
    public let transmissionTemplateId: String?
    /// the embedded data from the scanned code (from the {embed} template component), if any
    public let embeddedData: Int?
    /// the units of the embedded data, if any
    public let encodingUnit: Units?
    /// optional override for the product's price per `referenceUnit`
    public let referencePriceOverride: Int?
    /// optional override for the product's price
    public let priceOverride: Int?
    /// the lookup code we used to find the product in the database
    public let lookupCode: String
    /// the specified quantity
    public let specifiedQuantity: Int?

    public init(_ product: Product,
                _ lookupCode: String,
                _ transmissionCode: String?,
                templateId: String? = nil,
                transmissionTemplateId: String? = nil,
                embeddedData: Int? = nil,
                encodingUnit: Units? = nil,
                referencePriceOverride: Int? = nil,
                specifiedQuantity: Int?,
                priceOverride: Int? = nil) {
        self.product = product
        self.lookupCode = lookupCode
        self.transmissionCode = transmissionCode
        self.templateId = templateId
        self.transmissionTemplateId = transmissionTemplateId
        self.embeddedData = embeddedData
        self.encodingUnit = encodingUnit ?? product.encodingUnit
        self.referencePriceOverride = referencePriceOverride
        self.specifiedQuantity = specifiedQuantity
        self.priceOverride = priceOverride
    }
}

/// status of the last appdb update call
public enum AppDbAvailability {
    /// update is in progress or hasn't started yet
    case unknown
    /// update returned new data
    case newData
    /// update did not return new data
    case unchanged
    /// update was aborted and has received incomplete data.
    case incomplete
    /// an update is already in progress
    case inProgress
}

public protocol ProductProviding: AnyObject {
    
    /// get a product by its SKU
    func productBy(sku: String, shopId: Identifier<Shop>) -> Product?

    /// get a product by one of its scannable codes/templates
    func productBy(codes: [(String, String)], shopId: Identifier<Shop>) -> ScannedProduct?

    /// get a list of products by their SKUs
    func productsBy(skus: [String], shopId: Identifier<Shop>) -> [Product]

    /// get products matching `name`
    ///
    /// The project's `useFTS` flag must be `true` for this to work.
    ///
    /// - Parameter name: the string to search for. The search is case- and diacritic-insensitive
    /// - Returns: an array of matching `Product`s.
    ///   NB: the returned products do not have price information
    func productsBy(name: String, filterDeposits: Bool) -> [Product]

    /// searches for products whose scannable codes start with `prefix`
    ///
    /// - Parameters:
    ///   - prefix: the prefix to search for
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    ///   - templates: if set, the search matches any of the templates passed. if nil, only the built-in `default` template is matched
    /// - Returns: an array of matching `Product`s
    ///   NB: the returned products do not have price information
    func productsBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>) -> [Product]

    // MARK: - asynchronous variants of the product lookup methods

    /// asynchronously get a product by its SKU
    ///
    /// - Parameters:
    ///   - sku: the sku to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - result: the product found or the error
    func productBy(sku: String, shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping (_ result: Result<Product, ProductLookupError>) -> Void )

    /// asynchronously get a product by (one of) its scannable codes
    ///
    /// - Parameters:
    ///   - codes: the code/template pairs to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - result: the lookup result or the error
    func productBy(codes: [(String, String)], shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping (_ result: Result<ScannedProduct, ProductLookupError>) -> Void )
    
    var productAvailability: ProductAvailability { get }
}

public extension ProductProviding {
    func productBy(sku: String, shopId: Identifier<Shop>, completion: @escaping (_ result: Result<Product, ProductLookupError>) -> Void ) {
        self.productBy(sku: sku, shopId: shopId, forceDownload: false, completion: completion)
    }

    func productsBy(prefix: String, shopId: Identifier<Shop>) -> [Product] {
        return self.productsBy(prefix: prefix, filterDeposits: true, templates: nil, shopId: shopId)
    }

    func productsByName(_ name: String) -> [Product] {
        return self.productsBy(name: name, filterDeposits: true)
    }

    func productBy(codes: [(String, String)], shopId: Identifier<Shop>, completion: @escaping (_ result: Result<ScannedProduct, ProductLookupError>) -> Void ) {
        self.productBy(codes: codes, shopId: shopId, forceDownload: false, completion: completion)
    }
}

public protocol ProductStoring: AnyObject {
    /// returns the persistence object
    var database: AnyObject? { get }
    /// returns the path to the persistence object
    var databasePath: String { get }
    
    /// Check if a database file is present for this project
    func databaseExists() -> Bool

    /// Setup the product database
    ///
    /// The database can be used as soon as this method returns.
    ///
    /// - parameter update: if `.always` or `.ifOlderThan` , attempt to update the database to the latest revision
    /// - parameter forceFullDownload: if true, force a full download of the product database
    /// - parameter completion: This is called asynchronously on the main thread after the automatic database update check has finished
    /// - parameter dataAvailable: indicates if new data is available
    func setup(update: ProductDbUpdate, forceFullDownload: Bool, completion: @escaping ((_ dataAvailable: AppDbAvailability) -> Void))

    /// attempt to resume a previously interrupted update of the product database
    /// calling this method when there is no previous resumable download has no effect.
    ///
    /// - parameter completion: This is called asynchronously on the main thread after the database update check has finished
    /// - parameter dataAvailable: indicates if new data is available
    func resumeIncompleteUpdate(completion: @escaping (_ dataAvailable: AppDbAvailability) -> Void)

    /// stop the currently running product database update, if one is in progress.
    ///
    /// if possible, this will create the necessary resume data so that the download can be continued later
    /// by calling `resumeIncompleteUpdate(completion:)`
    func stopDatabaseUpdate()

    var revision: Int64 { get }
    var lastProductUpdate: Date { get }

    var appDbAvailability: AppDbAvailability { get }
    
    var schemaVersionMajor: Int { get }
    var schemaVersionMinor: Int { get }

    /// use only during development/debugging
    func removeDatabase()
}

public extension ProductStoring {
    func setup(completion: @escaping (AppDbAvailability) -> Void ) {
        self.setup(update: .always, forceFullDownload: false, completion: completion)
    }
    func removeDatabase() { }
}

public protocol ProductProvider: AnyObject, ProductProviding, ProductStoring {
    /// initialize a ProductDB instance with the given configuration
    /// - parameter config: a `SnabbleAPIConfig` object
    /// - parameter project: the snabble `Project`
    init(_ config: Config, _ project: Project)
}

public enum ProductDbUpdate {
    case always
    case never
    case ifOlderThan(Int) // age in seconds
}

final class ProductDB: ProductProvider {
    internal let supportedSchemaVersion = "1"

    private let dbName = "products.sqlite3"
    private var db: DatabaseQueue?
    private var dbDirectory: URL
    private let config: Config
    private let useFTS: Bool
    let project: Project

    /// revision of the current local product database
    public private(set) var revision: Int64 = 0

    /// major schema version of the current local database
    public private(set) var schemaVersionMajor = 0
    /// minor schema version of the current local database
    public private(set) var schemaVersionMinor = 0
    /// default availabilty (if no record in `availabilities` is found
    public private(set) var defaultAvailability = ProductAvailability.inStock
  
    /// date of last successful product update (i.e, whenever we last got a HTTP status 200 or 304)
    public private(set) var lastProductUpdate = Date(timeIntervalSinceReferenceDate: 0)

    public private(set) var appDbAvailability = AppDbAvailability.unknown

    private var updateInProgress = false

    internal var resumeData: Data?

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid {
        didSet {
            if oldValue != .invalid {
                UIApplication.shared.endBackgroundTask(oldValue)
            }
        }
    }
    internal var downloadTask: URLSessionDownloadTask? {
        willSet {
            if newValue != nil {
                backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: { [self] in
                    backgroundTaskIdentifier = .invalid
                })
            } else {
                backgroundTaskIdentifier = .invalid
            }
        }
    }
    private let switchMutex = Mutex()

    public var database: AnyObject? {
        return db
    }
    
    public var databasePath: String {
        return self.dbPathname()
    }
    
    public var productAvailability: ProductAvailability {
        return defaultAvailability
    }
    
    /// initialize a ProductDB instance with the given configuration
    /// - parameter config: a `ProductDBConfiguration` object
    public init(_ config: Config, _ project: Project) {
        self.config = config
        self.project = project

        self.useFTS = config.useFTS && project.links.shoppingListDB == nil

        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.dbDirectory = appSupportDir.appendingPathComponent(project.id.rawValue, isDirectory: true)
    }

    private func dbPathname(temporary: Bool = false) -> String {
        let prefix = temporary ? ProcessInfo().globallyUniqueString + "_" : ""
        let dbDir = self.dbDirectory.appendingPathComponent(prefix + self.dbName)
        return dbDir.path
    }

    func databaseExists() -> Bool {
        return FileManager.default.fileExists(atPath: self.dbPathname())
    }

    /// Setup the product database
    /// - Parameters:
    ///   - update: if `.always` or `.ifOlderThan` , attempt to update the database to the latest revision
    ///   - forceFullDownload: if true, force a full download of the product database
    ///   - completion: This is called asynchronously on the main thread after the automatic database update check has finished
    ///   - dataAvailable: indicates if the database was updated
    public func setup(update: ProductDbUpdate = .always, forceFullDownload: Bool = false, completion: @escaping (_ dataAvailable: AppDbAvailability) -> Void ) {
        // remove comments to simulate first app installation
//        let dbFile = self.dbPathname()
//        let fileManager = FileManager.default
//        if fileManager.fileExists(atPath: dbFile) {
//            try? fileManager.removeItem(atPath: dbFile)
//        }

        self.db = self.openDb()

        if let seedRevision = self.config.seedRevision, seedRevision > self.revision {
            self.db = nil
            self.unzipSeed()
            self.db = self.openDb()
        }

        let doUpdate: Bool
        switch update {
        case .always:
            doUpdate = true
        case .never:
            doUpdate = false
        case .ifOlderThan(let age):
            let now = Date()
            let diff = Calendar.current.dateComponents([.second], from: self.lastProductUpdate, to: now)
            doUpdate = diff.second! > age
        }

        if doUpdate {
            self.updateDatabase(forceFullDownload: forceFullDownload) { dataAvailable in
                self.executeInitialSQL()
                completion(dataAvailable)
            }
        } else {
            self.executeInitialSQL()
            completion(.unchanged)
        }
    }

    /// Attempt to update the product database
    /// - Parameters:
    ///   - forceFullDownload: if true, force a full download of the product database
    ///   - completion: This is called asynchronously on the main thread, after the update check has finished.
    ///   - dataAvailable: indicates if new data is available
    private func updateDatabase(forceFullDownload: Bool, completion: @escaping (_ dataAvailable: AppDbAvailability) -> Void ) {
        let schemaVersion = "\(self.schemaVersionMajor).\(self.schemaVersionMinor)"
        let revision = (forceFullDownload || !self.databaseExists()) ? 0 : self.revision

        if self.updateInProgress {
            return completion(.inProgress)
        }

        self.updateInProgress = true
        self.getAppDb(currentRevision: revision, schemaVersion: schemaVersion) { dbResponse in
            self.processAppDbResponse(dbResponse, completion)
        }
    }

    public func resumeIncompleteUpdate(completion: @escaping (_ dataAvailable: AppDbAvailability) -> Void ) {
        guard self.appDbAvailability == .incomplete else {
            return
        }

        guard self.resumeData != nil else {
            Log.warn("resumeAbortedUpdate called without resumeData?!?")
            return
        }

        self.resumeAppDbDownload { dbResponse in
            self.processAppDbResponse(dbResponse, completion)
        }
    }

    public func stopDatabaseUpdate() {
        downloadTask?.cancel { [self] data in
            resumeData = data
            appDbAvailability = data != nil ? .incomplete : .unknown
        }
    }

    private func processAppDbResponse(_ dbResponse: AppDbResponse, _ completion: @escaping (_ dataAvailable: AppDbAvailability) -> Void ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let tempDbPath = self.dbPathname(temporary: true)
            let performSwitch: Bool
            var dataAvailable = AppDbAvailability.unknown
            switch dbResponse {
            case .diff(let updateFile):
                Log.info("db update: got diff")
                performSwitch = self.copyAndUpdateDatabase(updateFile, tempDbPath)
                if performSwitch {
                    dataAvailable = .newData
                    self.lastProductUpdate = Date()
                } else {
                    Log.error("applying delta update failed, forcing full db download")
                    self.updateInProgress = false
                    self.updateDatabase(forceFullDownload: true, completion: completion)
                    return
                }
            case .full(let dbFile):
                Log.info("db update: got full db")
                performSwitch = self.writeFullDatabase(dbFile, tempDbPath)
                if performSwitch {
                    dataAvailable = .newData
                    self.lastProductUpdate = Date()
                }
            case .noUpdate:
                Log.info("db update: no new data")
                performSwitch = false
                dataAvailable = .unchanged
                self.lastProductUpdate = Date()
            case .httpError, .dataError:
                Log.info("db update: http error or no data")
                performSwitch = false
                dataAvailable = .unchanged
            case .aborted:
                Log.info("db update: download aborted, try again later")
                performSwitch = false
                dataAvailable = .incomplete
            }

            if self.useFTS {
                if dataAvailable == .newData {
                    self.createFulltextIndex(tempDbPath)
                } else {
                    let dbPath = self.dbPathname()
                    if self.ftsTablesMissing(dbPath) {
                        self.createFulltextIndex(dbPath)
                    }
                }
            }

            if performSwitch {
                self.switchDatabases(tempDbPath)
            } else {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: tempDbPath) {
                    try? fileManager.removeItem(atPath: tempDbPath)
                }
            }

            DispatchQueue.main.async {
                self.updateInProgress = false
                self.appDbAvailability = dataAvailable
                completion(dataAvailable)
            }
        }
    }

    private func createFulltextIndex(_ path: String) {
        Log.info("creating FTS index...")
        do {
            let db = try DatabaseQueue(path: path)
            try self.createFulltextIndex(db)
        } catch {
            var extendedResult: Int32 = 0
            if let dbError = error as? DatabaseError {
                extendedResult = dbError.extendedResultCode.rawValue
            }
            self.logError("create FTS failed: error \(error), extended error \(extendedResult)")
        }
    }

    private func ftsTablesMissing(_ path: String) -> Bool {
        do {
            var config = Configuration()
            config.readonly = true
            let db = try DatabaseQueue(path: path, configuration: config)
            let tableCount: Int = try db.inDatabase { db in
                let query = "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='searchByName'"
                if let count = try Int.fetchOne(db, sql: query) {
                    return count
                } else {
                    return 0
                }
            }
            return tableCount == 0
        } catch {
            var extendedResult: Int32 = 0
            if let dbError = error as? DatabaseError {
                extendedResult = dbError.extendedResultCode.rawValue
            }
            self.logError("check for FTS failed: error \(error), extended error \(extendedResult)")
        }
        return true
    }

    public func removeDatabase() {
        self.db = nil

        let fileManager = FileManager.default
        let dbFile = self.dbPathname()

        if fileManager.fileExists(atPath: dbFile) {
            try? fileManager.removeItem(atPath: dbFile)
        }
    }

    private func openDb() -> DatabaseQueue? {
        let fileManager = FileManager.default

        do {
            // ensure database directory exists
            if !fileManager.fileExists(atPath: self.dbDirectory.path) {
                try fileManager.createDirectory(at: self.dbDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            self.removePreviousUpdateRemnants()

            let dbFile = self.dbPathname()

            // copy our seed database to the app support directory if the file doesn't exist
            if !fileManager.fileExists(atPath: dbFile) {
                self.unzipSeed()
            }

            if !fileManager.fileExists(atPath: dbFile) {
                Log.info("no sqlite file found at \(dbFile)")
                return nil
            }

            Log.info("using sqlite db: \(dbFile)")
            var config = Configuration()
            config.readonly = true
            let db = try DatabaseQueue(path: dbFile, configuration: config)
            self.readMetadata(db)
            return db
        } catch let error {
            self.logError("openDb: db setup error \(error)")
            return nil
        }
    }

    private func unzipSeed() {
        guard let seedPath = self.config.seedDatabase else {
            return
        }

        Log.info("unzipping seed database")
        do {
            let seedUrl = URL(fileURLWithPath: seedPath)
            try Zip.unzipFile(seedUrl, destination: self.dbDirectory, overwrite: true, password: nil)
        } catch let error {
            self.logError("error while unzipping seed: \(error)")
        }

        if self.useFTS {
            self.createFulltextIndex(self.dbPathname())
        }

        do {
            let dbQueue = try DatabaseQueue(path: self.dbPathname())
            self.setLastUpdate(dbQueue)
        } catch {
            self.logError("error updating metadata: \(error)")
        }
    }

    /// create a new temporary database file from `dbFile`
    ///
    /// - Parameters:
    ///   - dbFile: the file to copy from
    ///   - tempDbPath: the filename to copy to
    /// - Returns: true if the database was written successfully and passes internal integrity checks,
    ///         false otherwise
    private func writeFullDatabase(_ dbFile: URL, _ tempDbPath: String) -> Bool {
        let fileManager = FileManager.default
        defer {
            try? fileManager.removeItem(at: dbFile)
        }

        do {
            if fileManager.fileExists(atPath: tempDbPath) {
                try fileManager.removeItem(atPath: tempDbPath)
            }
            let tmpUrl = URL(fileURLWithPath: tempDbPath)
            try fileManager.moveItem(at: dbFile, to: tmpUrl)

            // open the db and check its integrity
            let tempDb = try DatabaseQueue(path: tempDbPath)
            let ok = try checkIntegrity(tempDb)

            if ok {
                let metadata = self.metadata(tempDb)

                guard
                    let majorVersion = metadata[MetadataKeys.schemaVersionMajor],
                    let minorVersion = metadata[MetadataKeys.schemaVersionMinor],
                    let revision = metadata[MetadataKeys.revision],
                    majorVersion == self.supportedSchemaVersion
                else {
                    return false
                }

                self.setLastUpdate(tempDb)

                Log.info("new db: revision=\(revision), schema=\(majorVersion).\(minorVersion)")

                return true
            }
        } catch let error {
            var extendedError: Int32 = 0
            if let dbError = error as? DatabaseError {
                extendedError = dbError.extendedResultCode.rawValue
            }
            self.logError("writeFullDatabase: db update error \(error), extended error \(extendedError)")
        }

        if fileManager.fileExists(atPath: tempDbPath) {
            try? fileManager.removeItem(atPath: tempDbPath)
        }
        return false
    }

    private func checkIntegrity(_ dbQueue: DatabaseQueue) throws -> Bool {
        if !databaseExists() {
            Log.info("skip integrity check on first full d/l")
            return true
        }

        let start = Date.timeIntervalSinceReferenceDate

        let ok: Bool = try dbQueue.inDatabase { db in
            if let result = try String.fetchOne(db, sql: "pragma integrity_check") {
                return result.lowercased() == "ok"
            } else {
                return false
            }
        }
        let elapsed = Date.timeIntervalSinceReferenceDate - start
        Log.info("db integrity check: \(ok) took \(elapsed)s")
        if !ok {
            logError("db integrity check failed")
        }
        return ok
    }

    private func setLastUpdate(_ dbQueue: DatabaseQueue) {
        do {
            let now = Formatter.iso8601.string(from: Date())
            try dbQueue.inDatabase { db in
                try db.execute(sql: "insert or replace into metadata values(?,?)", arguments: [MetadataKeys.appLastUpdate, now])
            }
        } catch {
            self.logError("setLastUpdate failed: \(error)")
        }
    }

    private func copyAndUpdateDatabase(_ updateFile: URL, _ tempDbPath: String) -> Bool {
        let fileManager = FileManager.default
        defer {
            try? fileManager.removeItem(at: updateFile)
        }

        do {
            if fileManager.fileExists(atPath: tempDbPath) {
                try fileManager.removeItem(atPath: tempDbPath)
            }
            try fileManager.copyItem(atPath: self.dbPathname(), toPath: tempDbPath)

            let tempDb = try DatabaseQueue(path: tempDbPath)

            let statements = try String(contentsOf: updateFile, encoding: .utf8)
            try tempDb.inTransaction { db in
                try db.execute(sql: statements)
                return .commit
            }

            self.setLastUpdate(tempDb)
            try tempDb.vacuum()

            return true
        } catch let error {
            var extendedError: Int32 = 0
            if let dbError = error as? DatabaseError {
                extendedError = dbError.extendedResultCode.rawValue
            }
            self.logError("copyAndUpdateDatabase: db update error \(error), extended error \(extendedError)")

            try? fileManager.removeItem(atPath: tempDbPath)
            if let dbError = error as? DatabaseError, dbError.resultCode == .SQLITE_CORRUPT {
                // updating or vacuuming the copy reported a malformed database file, so we have to assume that the original was
                // corrupted to begin with. remove the file, and let the next db update start from scratch
                try? fileManager.removeItem(atPath: self.dbPathname())
            }
            return false
        }
    }

    private func switchDatabases(_ tempDbPath: String) {
        switchMutex.lock()
        defer { switchMutex.unlock() }

        let fileManager = FileManager.default
        do {
            let dbFile = self.dbPathname()
            let oldFile = dbFile + ".old"

            self.db = nil
            if fileManager.fileExists(atPath: oldFile) {
                try fileManager.removeItem(atPath: oldFile)
            }
            if fileManager.fileExists(atPath: dbFile) {
                try fileManager.moveItem(atPath: dbFile, toPath: oldFile)
            }
            try fileManager.moveItem(atPath: tempDbPath, toPath: dbFile)
            try? fileManager.removeItem(atPath: oldFile)
            self.db = self.openDb()
        } catch let error {
            try? fileManager.removeItem(atPath: tempDbPath)
            self.logError("switchDatabases: db switch error \(error)")
        }
    }

    private func readMetadata(_ db: DatabaseQueue) {
        let metadata = self.metadata(db)

        for (key, value) in metadata {
            switch key {
            case MetadataKeys.revision:
                self.revision = Int64(value) ?? 0
            case MetadataKeys.schemaVersionMajor:
                self.schemaVersionMajor = Int(value) ?? 0
            case MetadataKeys.schemaVersionMinor:
                self.schemaVersionMinor = Int(value) ?? 0
            case MetadataKeys.appLastUpdate:
                if let date = Formatter.iso8601.date(from: value) {
                    self.lastProductUpdate = date
                }
            case MetadataKeys.defaultAvailability:
                self.defaultAvailability = ProductAvailability(rawValue: Int(value) ?? 0)
            default:
                break
            }
        }
    }

    private func executeInitialSQL() {
        guard Snabble.debugMode, let statements = self.config.initialSQL, !statements.isEmpty else {
            return
        }

        do {
            let dbQueue = try DatabaseQueue(path: self.dbPathname())
            for statement in statements {
                Log.warn("execute SQL: \(statement)")
                try dbQueue.inDatabase { db in
                    try db.execute(sql: statement)
                }
            }
        } catch {
            Log.error("executeInitialSQL: \(error)")
        }
    }

    // remove any temporary db files that were erroneously left on disk during previous runs
    private func removePreviousUpdateRemnants() {
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(atPath: self.dbDirectory.path) else {
            return
        }

        for file in files where file.hasSuffix("_" + self.dbName) {
            let fileUrl = self.dbDirectory.appendingPathComponent(file)
            try? fileManager.removeItem(at: fileUrl)
        }
    }
}

// MARK: - product access methods
extension ProductDB {
    /// get a product by its SKU
    ///
    /// - Parameter sku: the SKU of the product to get
    /// - Returns: a `Product` if found; nil otherwise
    public func productBy(sku: String, shopId: Identifier<Shop>) -> Product? {
        guard let db = self.db else {
            return nil
        }

        return self.productBy(db, sku: sku, shopId: shopId)
    }

    /// get a list of products by their SKUs
    ///
    /// the ordering of the returned products is unspecified
    ///
    /// - Parameter skus: SKUs of the products to get
    /// - Returns: an array of `Product`
    public func productsBy(skus: [String], shopId: Identifier<Shop>) -> [Product] {
        guard let db = self.db, !skus.isEmpty else {
            return []
        }

        return self.productsBy(db, skus: skus, shopId: shopId)
    }

    /// get a product by one of its scannable codes/template pairs
    public func productBy(codes: [(String, String)], shopId: Identifier<Shop>) -> ScannedProduct? {
        guard let db = self.db else {
            return nil
        }

        return self.productBy(db, codes: codes, shopId: shopId)
    }

    /// get products matching `name`
    ///
    /// The project's `useFTS` flag must be `true` for this to work.
    ///
    /// - Parameters:
    ///   - name: the string to search for. The search is case- and diacritic-insensitive
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    /// - Returns: an array of matching Products
    public func productsBy(name: String, filterDeposits: Bool = true) -> [Product] {
        guard let db = self.db else {
            return []
        }

        if !self.useFTS {
            Log.warn("productsByName called, but useFTS not set")
        }

        return self.productsBy(db, name: name, filterDeposits: filterDeposits, shopId: "")
    }

    ///
    /// searches for products whose scannable code starts with `prefix`
    ///
    /// - Parameters:
    ///   - prefix: the prefix to search for
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    /// - Returns: an array of matching Products
    public func productsBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>) -> [Product] {
        guard let db = self.db else {
            return []
        }

        return self.productsBy(db, prefix: prefix, filterDeposits: filterDeposits, templates: templates, shopId: shopId)
    }

    // MARK: - asynchronous requests

    private func lookupLocally(forceDownload: Bool) -> Bool {
        let now = Date.timeIntervalSinceReferenceDate
        let age = now - self.lastProductUpdate.timeIntervalSinceReferenceDate
        let ageOk = age < self.config.maxProductDatabaseAge
        return !forceDownload && ageOk
    }

    /// asynchronously get a product by its SKU
    ///
    /// invokes the completion handler on the main thread with the result of the lookup
    ///
    /// - Parameters:
    ///   - sku: the SKU to look for
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    public func productBy(sku: String, shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping (_ result: Result<Product, ProductLookupError>) -> Void) {
        if self.lookupLocally(forceDownload: forceDownload), let product = self.productBy(sku: sku, shopId: shopId) {
            DispatchQueue.main.async {
                if product.availability == .notAvailable {
                    completion(.failure(.notFound))
                } else {
                    completion(.success(product))
                }
            }
            return
        }

        if let url = self.project.links.resolvedProductBySku?.href {
            self.resolveProductLookup(url: url, sku: sku, shopId: shopId, completion: completion)
        } else {
            completion(.failure(.notFound))
        }
    }

    /// asynchronously get a product by (one of) it scannable codes
    ///
    /// invokes the completion handler on the main thread with the result of the lookup
    ///
    /// - Parameters:
    ///   - codes: the codes/templates to look for
    ///   - shopId: the shop id
    ///   - forceDownload: if true, skip the lookup in the local DB
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    public func productBy(codes: [(String, String)], shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping (_ result: Result<ScannedProduct, ProductLookupError>) -> Void) {
        if self.lookupLocally(forceDownload: forceDownload), let result = self.productBy(codes: codes, shopId: shopId) {
            DispatchQueue.main.async {
                if result.product.availability == .notAvailable {
                    completion(.failure(.notFound))
                } else {
                    completion(.success(result))
                }
            }
            return
        }

        if let url = self.project.links.resolvedProductLookUp?.href {
            self.resolveProductsLookup(url, codes, shopId, completion: completion)
        } else {
            completion(.failure(.notFound))
        }
    }

    func logError(_ msg: String) {
        self.project.logError(msg)
    }
}
