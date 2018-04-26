//
//  ProductDB.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import GRDB
import Zip

/// keys of well-known entries in the metadata table
public struct MetadataKeys {
    public static let revision = "revision"
    public static let schemaVersionMajor = "schemaVersionMajor"
    public static let schemaVersionMinor = "schemaVersionMinor"
}

public struct ProductDBConfiguration {
    /// Name of the database file. Default: `products.sqlite3`
    public var dbName = "products.sqlite3"

    /// Directory where the database should be stored, will be created if it doesn't exist.
    /// Default: the app's "Application Support" directory
    public var dbDirectory: String

    /// where to get database updates from?
    public var updateUrl = ""

    /// URL for sku lookup
    public var lookupBySkuUrl = ""

    /// URL for scannable code lookup
    public var lookupByCodeUrl = ""

    /// URL for weighed item id lookup
    public var lookupByIdUrl = ""

    /// if the app bundle contains a zipped seed database, set this to the path in the bundle,
    /// e.g. using `cfg.seedDbPath = Bundle.main.path(forResource: "seed", ofType: "zip")`
    /// this file is assumed to be a ZIP archive, containing a file with the same name as the value of `dbName`
    public var seedDbPath: String?

    /// if the app bundle contains a zipped seed database, this must contain the revision of that database.
    public var seedRevision: Int64?

    public init() {
        self.dbDirectory = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
    }

    func dbPathname(temp: Bool = false) -> String {
        let dbDir = self.dbDirectory
        let path = dbDir + (temp ? "/tmp_" : "/") + self.dbName

        return path
    }
}

public protocol ProductProvider: class {
    /// initialize a ProductDB instance with the given configuration
    /// - parameter config: a `ProductDBConfiguration` object
    init(_ config: ProductDBConfiguration)

    /// Setup the product database
    func setup(completion: @escaping ((Bool) -> ()))

    /// Attempt to update the product database
    func updateDatabase(completion: @escaping (Bool) -> ())

    /// get a product by its SKU
    func productBySku(_ sku: String) -> Product?

    /// get a list of products by their SKUs
    func productsBySku(_ skus: [String]) -> [Product]

    /// get boosted products
    ///
    /// returns a list of products that have a non-null `boost` value and a valid image URL
    /// the returned list is sorted by descending boost value
    ///
    /// - Parameter limit: number of products to get
    /// - Returns: an array of `Product`
    func boostedProducts(limit: Int) -> [Product]

    /// get discounted products
    ///
    /// returns a list of all products that have a discounted price and a valid image URL
    ///
    /// - Returns: an array of `Product`
    func discountedProducts() -> [Product]

    /// get a product by (one of) its scannable codes
    func productByScannableCode(_ code: String) -> Product?

    /// get a product by its weighItemId
    func productByWeighItemId(_ weighItemId: String) -> Product?

    ///
    /// get products matching `name`
    ///
    /// - Parameter name: the string to search for. The search is case- and diacritic-insensitive
    /// - Returns: an array of matching Products
    func productsByName(_ name: String, filterDeposits: Bool) -> [Product]

    ///
    /// searches for products whose scannable codes start with `prefix`
    ///
    /// - Parameters:
    ///   - prefix: the prefix to search for
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    /// - Returns: an array of matching Products
    func productsByScannableCodePrefix(_ prefix: String, filterDeposits: Bool) -> [Product]

    /// asynchronous variants of the product lookup methods

    /// get a product by its SKU
    ///
    /// - Parameters:
    ///   - sku: the sku to look for
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    func productBySku(_ sku: String, completion: @escaping (_ product: Product?, _ error: Bool) -> () )

    /// get a product by (one of) its scannable codes
    ///
    /// - Parameters:
    ///   - code: the code to look for
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    func productByScannableCode(_ code: String, completion: @escaping (_ product: Product?, _ error: Bool) -> () )

    /// get a product by (one of) it weigh item ids
    ///
    /// - Parameters:
    ///   - weighItemId: the id to look for
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    func productByWeighItemId(_ weighItemId: String, completion: @escaping (_ product: Product?, _ error: Bool) -> () )
}

final public class ProductDB: ProductProvider {

    internal let supportedSchemaVersion = 1

    internal let config: ProductDBConfiguration

    private var db: DatabaseQueue?

    /// revision of the current local product database
    private(set) public var revision: Int64 = 0

    /// major schema version of the current local database
    private(set) public var schemaVersionMajor = 0
    /// minor schema version of the current local database
    private(set) public var schemaVersionMinor = 0

    /// date of last successful product update (i.e, whenever we last got a HTTP status 200 or 304)
    private(set) public var lastProductUpdate = Date()

    /// initialize a ProductDB instance with the given configuration
    /// - parameter config: a `ProductDBConfiguration` object
    public init(_ config: ProductDBConfiguration) {
        self.config = config
    }

    /**
     Setup the product database

     The database can be used as soon as this method returns.

     - parameter completion: a closure taking a `Bool` parameter.
        This is called asynchronously on the main thread, once after the database present on the device has been opened,
        and once more later, after the automatic database update check has finished.
        The closure's parameter indicates whether new data is available or not.
    */
    public func setup(completion: @escaping (Bool) -> () ) {
        self.db = self.openDb()

        if let seedRevision = self.config.seedRevision, seedRevision > self.revision {
            self.db = nil
            self.unzipSeed()
            self.db = openDb()
        }

        DispatchQueue.main.async {
            completion(false)
        }

        self.updateDatabase(completion: completion)
    }

    /**
     Attempt to update the product database

     - parameter completion: a closure taking a `Bool` parameter.
        This is called asynchronously on the main thread, after the update check has finished.
        The parameter indicates whether new data is available or not.
    */
    public func updateDatabase(completion: @escaping (Bool)->() ) {
        let schemaVersion = "\(self.schemaVersionMajor).\(self.schemaVersionMinor)"
        self.getAppDb(currentRevision: self.revision, schemaVersion: schemaVersion) { dbResponse in
            self.lastProductUpdate = Date()

            DispatchQueue.global(qos: .userInitiated).async {
                let performSwitch: Bool
                let newData: Bool
                switch dbResponse {
                case .diff(let statements):
                    NSLog("db update: got diff")
                    performSwitch = self.copyAndUpdateDatabase(statements)
                    newData = true
                case .full(let data, let revision):
                    NSLog("db update: got full db, rev=\(revision)")
                    performSwitch = self.writeFullDatabase(data, revision)
                    newData = true
                case .noUpdate:
                    NSLog("db update: no new data")
                    performSwitch = false
                    newData = false
                case .httpError, .dataError:
                    NSLog("db update: http error or no data")
                    performSwitch = false
                    newData = false
                }

                if performSwitch {
                    self.switchDatabases()
                } else {
                    let tempDbPath = self.config.dbPathname(temp: true)
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: tempDbPath) {
                        try? fileManager.removeItem(atPath: tempDbPath)
                    }
                }

                DispatchQueue.main.async {
                    completion(newData)
                }
            }
        }
    }

    private func openDb() -> DatabaseQueue? {
        let fileManager = FileManager.default

        do {
            // ensure database directory exists
            if !fileManager.fileExists(atPath: self.config.dbDirectory) {
                try fileManager.createDirectory(atPath: self.config.dbDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            let dbFile = self.config.dbPathname()
            NSLog("using sqlite db: \(dbFile)")

            // remove comments to simulate first app installation
//            if fileManager.fileExists(atPath: dbFile) {
//                try fileManager.removeItem(atPath: dbFile)
//            }

            // copy our seed database to the app support directory if the file doesn't exist
            if !fileManager.fileExists(atPath: dbFile) {
                self.unzipSeed()
            }

            var config = Configuration()
            config.readonly = true
            let db = try DatabaseQueue(path: dbFile, configuration: config)
            self.readMetadata(db)
            return db
        } catch let error {
            NSLog("db setup error \(error)")
            return nil
        }
    }

    private func unzipSeed() {
        if let seedPath = self.config.seedDbPath {
            do {
                let seedUrl = URL(fileURLWithPath: seedPath)
                try Zip.unzipFile(seedUrl, destination: URL(fileURLWithPath: self.config.dbDirectory), overwrite: true, password: nil)
            } catch let error {
                NSLog("error while unzipping seed: \(error)")
            }
        }
    }

    /// create a new temporary database file from `data`
    ///
    /// - Parameters:
    ///   - data: the bytes to write
    ///   - revision: the revision of this new database
    /// - Returns: true if the database was written successfully and passes internal integrity checks,
    ///         false otherwise
    private func writeFullDatabase(_ data: Data, _ revision: Int) -> Bool {
        let tempDbPath = self.config.dbPathname(temp: true)
        let fileManager = FileManager.default

        do {
            if fileManager.fileExists(atPath: tempDbPath) {
                try fileManager.removeItem(atPath: tempDbPath)
            }
            let tmpUrl = URL(fileURLWithPath: tempDbPath)
            try data.write(to: tmpUrl, options: .atomic)

            // open the db and check its integrity
            let tempDb = try DatabaseQueue(path: tempDbPath)
            let ok: Bool = try tempDb.inDatabase { db in
                if let result = try String.fetchOne(db, "pragma integrity_check") {
                    return result.lowercased() == "ok"
                } else {
                    return false
                }
            }

            if ok {
                let result = try tempDb.inDatabase { db in
                    return try String.fetchAll(db, """
                        select value from metadata where key='\(MetadataKeys.schemaVersionMajor)'
                        union
                        select value from metadata where key='\(MetadataKeys.schemaVersionMinor)'
                        """)
                }
                guard result.count == 2 else {
                    return false
                }

                let majorVersion = Int(result[0]) ?? 0
                let minorVersion = Int(result[1]) ?? 0

                if majorVersion != self.supportedSchemaVersion {
                    return false
                }

                let shouldSwitch = revision > self.revision || minorVersion > self.schemaVersionMinor
                if shouldSwitch {
                    NSLog("new db: revision=\(revision), schema=\(majorVersion).\(minorVersion)")
                }
                return shouldSwitch
            }
        } catch let error {
            NSLog("db update error \(error)")
        }

        if fileManager.fileExists(atPath: tempDbPath) {
            try? fileManager.removeItem(atPath: tempDbPath)
        }
        return false
    }

    private func copyAndUpdateDatabase(_ statements: String) -> Bool {
        let tempDbPath = self.config.dbPathname(temp: true)
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: tempDbPath) {
                try fileManager.removeItem(atPath: tempDbPath)
            }
            try FileManager.default.copyItem(atPath: self.config.dbPathname(), toPath: tempDbPath)

            let tempDb = try DatabaseQueue(path: tempDbPath)

            try tempDb.inTransaction { db in
                try db.execute(statements)
                return .commit
            }

            try tempDb.inDatabase { db in
                try db.execute("vacuum")
            }
            return true
        } catch let error {
            NSLog("db update error \(error)")

            try? fileManager.removeItem(atPath: tempDbPath)
            return false
        }
    }

    private func switchDatabases() {
        do {
            let fileManager = FileManager.default
            let dbFile = self.config.dbPathname()
            let oldFile = dbFile + ".old"
            let tmpFile = self.config.dbPathname(temp: true)
            try synchronized(self) {
                self.db = nil
                if fileManager.fileExists(atPath: oldFile) {
                    try fileManager.removeItem(atPath: oldFile)
                }
                if fileManager.fileExists(atPath: dbFile) {
                    try fileManager.moveItem(atPath: dbFile, toPath: oldFile)
                }
                try fileManager.moveItem(atPath: tmpFile, toPath: dbFile)
                self.db = openDb()
            }
            if fileManager.fileExists(atPath: oldFile) {
                try fileManager.removeItem(atPath: oldFile)
            }
        } catch let error {
            NSLog("db switch error \(error)")
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
            default:
                break
            }
        }
    }

}

/// run `closure` synchronized using `lock`
func synchronized<T>(_ lock: Any, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}

// MARK: - product access methods
extension ProductDB {

    /// get a product by its SKU
    public func productBySku(_ sku: String) -> Product? {
        guard let db = self.db else {
            return nil
        }

        return self.productBySku(db, sku)
    }

    /// get a list of products by their SKUs
    public func productsBySku(_ skus: [String]) -> [Product] {
        guard let db = self.db, skus.count > 0 else {
            return []
        }

        return self.productsBySku(db, skus)
    }

    /// get boosted products
    ///
    /// returns a list of products that have a non-null `boost` value and a valid image URL
    /// the returned list is sorted by descending boost value
    ///
    /// - Parameter limit: number of products to get
    /// - Returns: an array of `Product`
    public func boostedProducts(limit: Int) -> [Product] {
        guard let db = self.db else {
            return []
        }

        return self.boostedProducts(db, limit: limit)
    }

    /// get discounted products
    ///
    /// returns a list of all products that have a discounted price and a valid image URL
    ///
    /// - Returns: an array of `Product`
    public func discountedProducts() -> [Product] {
        guard let db = self.db else {
            return []
        }

        return self.discountedProducts(db)
    }

    /// get a product by its scannable code
    public func productByScannableCode(_ code: String) -> Product? {
        guard let db = self.db else {
            return nil
        }

        return self.productByScannableCode(db, code)
    }

    /// get a product by its weighItemId
    public func productByWeighItemId(_ weighItemId: String) -> Product? {
        guard let db = self.db else {
            return nil
        }

        return self.productByWeighItemId(db, weighItemId)
    }

    /// get products matching `name`
    ///
    /// - Parameters:
    ///   - name: the string to search for. The search is case- and diacritic-insensitive
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    /// - Returns: an array of matching Products
    public func productsByName(_ name: String, filterDeposits: Bool = true) -> [Product] {
        guard let db = self.db else {
            return []
        }

        return self.productsByName(db, name, filterDeposits)
    }

    ///
    /// searches for products whose scannable code starts with `prefix`
    ///
    /// - Parameters:
    ///   - prefix: the prefix to search for
    ///   - filterDeposits: if true, products with `isDeposit==true` are not returned
    /// - Returns: an array of matching Products
    public func productsByScannableCodePrefix(_ prefix: String, filterDeposits: Bool = true) -> [Product] {
        guard let db = self.db else {
            return []
        }

        return self.productsByScannableCodePrefix(db, prefix, filterDeposits)
    }

    /// get a product by its SKU
    ///
    /// invokes the completion handler on the main thread with the result of the lookup
    ///
    /// - Parameters:
    ///   - sku: the SKU to look for
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    public func productBySku(_ sku: String, completion: @escaping (_ product: Product?, _ error: Bool) -> ()) {
        if let product = self.productBySku(sku) {
            DispatchQueue.main.async {
                completion(product, false)
            }
            return
        }

        self.getSingleProduct(self.config.lookupBySkuUrl, "{sku}", sku, completion: completion)
    }

    /// get a product by (one of) it scannable codes
    ///
    /// invokes the completion handler on the main thread with the result of the lookup
    ///
    /// - Parameters:
    ///   - code: the code to look for
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    public func productByScannableCode(_ code: String, completion: @escaping (_ product: Product?, _ error: Bool) -> ()) {
        if let product = self.productByScannableCode(code) {
            DispatchQueue.main.async {
                completion(product, false)
            }
            return
        }

        self.getSingleProduct(self.config.lookupByCodeUrl, "{code}", code, completion: completion)
    }

    /// get a product by (one of) it weigh item ids
    ///
    /// invokes the completion handler on the main thread with the result of the lookup
    ///
    /// - Parameters:
    ///   - weighItemId: the id to look for
    ///   - product: the product found, or nil.
    ///   - error: whether an error occurred during the lookup.
    public func productByWeighItemId(_ weighItemId: String, completion: @escaping (_ product: Product?, _ error: Bool) -> ()) {
        if let product = self.productByWeighItemId(weighItemId) {
            DispatchQueue.main.async {
                completion(product, false)
            }
            return
        }

        self.getSingleProduct(self.config.lookupByIdUrl, "{id}", weighItemId, completion: completion)
    }

}
