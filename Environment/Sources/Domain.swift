//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2024-06-03.
//

import Foundation

public enum Domain: String {
    case testing
    case staging
    case production = "prod"
    
    var name: String {
        rawValue
    }
    
    public var apiURLString: String {
        return "https://api.\(host)"
    }

    public var retailerURLString: String {
        return "https://retailer.\(host)"
    }

    public var host: String {
        switch self {
        case .testing:
            return "snabble-testing.io"
        case .staging:
            return "snabble-staging.io"
        case .production:
            return "snabble.io"
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
