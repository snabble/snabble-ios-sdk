//
//  Environment.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

public enum Domain: String {
    case testing
    case staging
    case production

    public var headerFields: [String: String] {
        return [
            "Content-Type": "application/json"
        ]
    }

    public var baseURL: URL {
        switch self {
        case .testing:
            return "https://api.snabble-testing.io"
        case .staging:
            return "https://api.snabble-staging.io"
        case .production:
            return "https://api.snabble.io"
        }
    }
}

extension Domain {
    public var name: String {
        switch self {
        case .testing, .staging:
            return rawValue
        case .production:
            return "prod"
        }
    }
}

extension Domain: Equatable {}

extension URL: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension URL: @retroactive ExpressibleByUnicodeScalarLiteral {}
extension URL: Swift.ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        self = URL(string: "\(value)")!
    }
}
