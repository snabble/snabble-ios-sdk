//
//  Environment.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

public enum Domain {
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

extension Domain: Equatable {}

extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        self = URL(string: "\(value)")!
    }
}
