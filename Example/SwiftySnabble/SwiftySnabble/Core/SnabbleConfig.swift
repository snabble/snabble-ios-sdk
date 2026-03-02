//
//  SnabbleConfig.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 06.09.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleCore

extension Config {
    static var appId: String {
        "snabble-sdk-demo-app-oguh3x"
    }

    static var production: Self {
        let environment: Snabble.Environment = .production
        return .init(
            appId: appId,
            secret: environment.secret,
            environment: environment
        )
    }

    static var staging: Self {
        let environment: Snabble.Environment = .staging
        return .init(
            appId: appId,
            secret: environment.secret,
            environment: environment
        )
    }

    static var testing: Self {
        let environment: Snabble.Environment = .testing
        return .init(
            appId: appId,
            secret: environment.secret,
            environment: environment
        )
    }
    
    static func config(for environment: Snabble.Environment) -> Self {
        switch environment {
        case .testing:
            return Self.testing
        case .staging:
            return Self.staging
        case .production:
            return Self.production
        }
    }
}
