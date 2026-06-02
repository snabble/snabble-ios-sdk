//
//  ProductStoring.swift
//  
//
//  Created by Uwe Tilemann on 04.11.22.
//

import Foundation

/// status of the last appdb update call
public enum ProductStoreAvailability: Sendable {
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

public protocol ProductStoring: AnyObject {
    /// returns the persistence object
    var database: AnyObject? { get }
    /// returns the path to the persistence object
    var databasePath: String { get }
    
    /// Check if a database file is present for this project
    var databaseExists: Bool { get }

    /// Setup the product database
    ///
    /// The database can be used as soon as this method returns.
    ///
    /// - parameter update: if `.always` or `.ifOlderThan` , attempt to update the database to the latest revision
    /// - parameter forceFullDownload: if true, force a full download of the product database
    /// - parameter completion: This is called asynchronously on the main thread after the automatic database update check has finished
    /// - parameter dataAvailable: indicates if new data is available
    func setup(update: ProductDbUpdate, forceFullDownload: Bool, completion: @escaping @Sendable (_ dataAvailable: ProductStoreAvailability) -> Void)

    /// attempt to resume a previously interrupted update of the product database
    /// calling this method when there is no previous resumable download has no effect.
    ///
    /// - parameter completion: This is called asynchronously on the main thread after the database update check has finished
    /// - parameter dataAvailable: indicates if new data is available
    func resumeIncompleteUpdate(completion: @escaping @Sendable (_ dataAvailable: ProductStoreAvailability) -> Void)

    /// stop the currently running product database update, if one is in progress.
    ///
    /// if possible, this will create the necessary resume data so that the download can be continued later
    /// by calling `resumeIncompleteUpdate(completion:)`
    func stopDatabaseUpdate()

    var revision: Int64 { get }
    var lastUpdate: Date { get }

    var availability: ProductStoreAvailability { get }
    var isUpToDate: Bool { get }
    
    var supportFulltextSearch: Bool { get }
    
    var schemaVersionMajor: Int { get }
    var schemaVersionMinor: Int { get }

    /// use only during development/debugging
    func removeDatabase()
}

public extension ProductStoring {
    func setup(completion: @escaping @Sendable (ProductStoreAvailability) -> Void ) {
        self.setup(update: .always, forceFullDownload: false, completion: completion)
    }
    
    func removeDatabase() { }
}
