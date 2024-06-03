//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2024-06-03.
//

import Foundation

public enum CustomProperty: Hashable {
    case externalBillingSubjectLimit(projectId: String)
}

/// General config data for using the snabble.
/// Applications must call `Snabble.setup(config: completion:)` with an instance of this struct before they make their first API call.
public struct Configuration {
    /// the appID assigned by snabble
    public let appId: String
    /// the environment  to use
    public let domain: Domain
    /// the secrect assigned by snabble, used to retrieve authorization tokens
    public let appSecret: String

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

    // Workaround: Bug Fix #APPS-995
    // https://snabble.atlassian.net/browse/APPS-995
    public var showExternalBilling = true

    // debug mode only:
    // SQL statements that are executed just before the product database is opened
    public var initialSQL: [String]?
    
    /// Custom Properties
    public var customProperties: [CustomProperty: Any] = [:]
    
    /// Initialize the configuration for Snabble
    /// - Parameters:
    ///   - appId: Provide your personal `appId`
    ///   - secret: The secret matching your `appId`
    ///   - domain: Choose a domain you want to use
    public init(appId: String, appSecret: String, domain: Domain = .production) {
        self.appId = appId
        self.domain = domain
        self.appSecret = appSecret
    }
}
