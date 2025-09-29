//
//  ProductDatabase.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import GRDB
import ZIPFoundation

#if canImport(UIKit)
import UIKit
#endif

/// keys of well-known entries in the metadata table
public enum MetadataKeys {
    public static let revision = "revision"
    public static let schemaVersionMajor = "schemaVersionMajor"
    public static let schemaVersionMinor = "schemaVersionMinor"
    public static let defaultAvailability = "defaultAvailability"

    fileprivate static let appLastUpdate = "app_lastUpdate"
}

public enum ProductDbUpdate {
    case always
    case never
    case ifOlderThan(Int) // age in seconds
}

final class ProductDatabase: ProductStoring, @unchecked Sendable {
    
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
    public private(set) var lastUpdate = Date(timeIntervalSinceReferenceDate: 0)

    public private(set) var availability = ProductStoreAvailability.unknown

    private var updateInProgress = false

    internal var resumeData: Data?

#if os(iOS)
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid {
        didSet {
            if oldValue != .invalid {
                DispatchQueue.main.async {
                    UIApplication.shared.endBackgroundTask(oldValue)
                }
            }
        }
    }
#endif

    internal var downloadTask: URLSessionDownloadTask? {
        willSet {
#if os(iOS)
            if newValue != nil {
                DispatchQueue.main.async { [weak self] in
                    let taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                        DispatchQueue.main.async {
                            self?.backgroundTaskIdentifier = .invalid
                        }
                    })
                    self?.backgroundTaskIdentifier = taskId
                }
            } else {
                backgroundTaskIdentifier = .invalid
            }
#endif
        }
    }
    private let switchMutex = Mutex()

    public var database: AnyObject? {
        return db
    }
    
    public var databasePath: String {
        return self.dbPathname()
    }

    public var isUpToDate: Bool {
        let now = Date.timeIntervalSinceReferenceDate
        let age = now - self.lastUpdate.timeIntervalSinceReferenceDate
        let ageOk = age < self.config.maxProductDatabaseAge
        
        return ageOk
    }
    
    public var supportFulltextSearch: Bool {
        return self.useFTS
    }
    
    /// initialize a ProductDatabase instance with the given configuration
    /// - parameter config: a `Config` structure
    /// - parameter project: the snabble `Project`
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

    var databaseExists: Bool {
        return FileManager.default.fileExists(atPath: self.dbPathname())
    }

    /// Setup the product database
    /// - Parameters:
    ///   - update: if `.always` or `.ifOlderThan` , attempt to update the database to the latest revision
    ///   - forceFullDownload: if true, force a full download of the product database
    ///   - completion: This is called asynchronously on the main thread after the automatic database update check has finished
    ///   - dataAvailable: indicates if the database was updated
    public func setup(update: ProductDbUpdate = .always, forceFullDownload: Bool = false, completion: @escaping @Sendable (_ dataAvailable: ProductStoreAvailability) -> Void ) {
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
            let diff = Calendar.current.dateComponents([.second], from: self.lastUpdate, to: now)
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
    private func updateDatabase(forceFullDownload: Bool, completion: @escaping @Sendable (_ dataAvailable: ProductStoreAvailability) -> Void ) {
        let schemaVersion = "\(self.schemaVersionMajor).\(self.schemaVersionMinor)"
        let revision = (forceFullDownload || !self.databaseExists) ? 0 : self.revision

        if self.updateInProgress {
            return completion(.inProgress)
        }

        self.updateInProgress = true
        self.getAppDb(currentRevision: revision, schemaVersion: schemaVersion) { dbResponse in
            self.processAppDbResponse(dbResponse, completion)
        }
    }

    public func resumeIncompleteUpdate(completion: @escaping @Sendable (_ dataAvailable: ProductStoreAvailability) -> Void ) {
        guard self.availability == .incomplete else {
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
            availability = data != nil ? .incomplete : .unknown
        }
    }

    private func processAppDbResponse(_ dbResponse: AppDbResponse, _ completion: @escaping @Sendable (_ dataAvailable: ProductStoreAvailability) -> Void ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let tempDbPath = self.dbPathname(temporary: true)
            let performSwitch: Bool
            var dataAvailable = ProductStoreAvailability.unknown
            switch dbResponse {
            case .diff(let updateFile):
                Log.info("db update: got diff")
                performSwitch = self.copyAndUpdateDatabase(updateFile, tempDbPath)
                if performSwitch {
                    dataAvailable = .newData
                    self.lastUpdate = Date()
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
                    self.lastUpdate = Date()
                }
            case .noUpdate:
                Log.info("db update: no new data")
                performSwitch = false
                dataAvailable = .unchanged
                self.lastUpdate = Date()
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
                self.availability = dataAvailable
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
        
        let fileManager = FileManager.default
        let seedUrl = URL(fileURLWithPath: seedPath)

        Log.info("unzipping seed database")
        do {
            try fileManager.removeItem(at: self.dbDirectory)
            if #available(iOS 16.0, *) {
                try fileManager.createDirectory(atPath: self.dbDirectory.path(percentEncoded: true), withIntermediateDirectories: true, attributes: nil)
            } else {
                try fileManager.createDirectory(atPath: self.dbDirectory.path, withIntermediateDirectories: true, attributes: nil)
            }
            try fileManager.unzipItem(at: seedUrl, to: self.dbDirectory)
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
        if !databaseExists {
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
                    self.lastUpdate = date
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
