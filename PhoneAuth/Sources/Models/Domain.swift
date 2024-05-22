//
//  Environment.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import SnabbleNetwork

public enum Domain {
    case testing
    case staging
    case production
}

extension Domain {
    func toDTO() -> SnabbleNetwork.Domain {
        switch self {
        case .production:
            return .production
        case .staging:
            return .staging
        case .testing:
            return .testing
        }
    }
}

extension SnabbleNetwork.Domain {
    func fromDTO() -> Domain {
        switch self {
        case .production:
            return .production
        case .staging:
            return .staging
        case .testing:
            return .testing
        }
    }
}
