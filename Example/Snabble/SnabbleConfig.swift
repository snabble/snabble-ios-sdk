//
//  SnabbleConfig.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 06.09.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleCore
import SnabbleEnvironment

extension Configuration {
    static var appId: String {
        "snabble-sdk-demo-app-oguh3x"
    }

    static var production: Self {
        let domain: Domain = .production
        return .init(
            appId: appId,
            appSecret: domain.secret,
            domain: domain
        )
    }

    static var staging: Self {
        let domain: Domain = .staging
        return .init(
            appId: appId,
            appSecret: domain.secret,
            domain: domain
        )
    }

    static var testing: Self {
        let domain: Domain = .testing
        return .init(
            appId: appId,
            appSecret: domain.secret,
            domain: domain
        )
    }
    
    static func config(for domain: SnabbleEnvironment.Domain) -> Self {
        switch domain {
        case .testing:
            return Self.testing
        case .staging:
            return Self.staging
        case .production:
            return Self.production
        }
    }
}
