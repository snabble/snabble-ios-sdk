//
//  Environment.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation

public enum Environment {
    case development
    case staging
    case production

    var baseURL: URL {
        switch self {
        case .development:
            return "https://payment.snabble-testing.io"
        case .staging:
            return "https://payment.snabble-staging.io"
        case .production:
            return "https://payment.snabble.io"
        }
    }
}
