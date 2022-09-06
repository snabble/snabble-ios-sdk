//
//  SnabbleConfig.swift
//  SnabbleSampleApp
//
//  Created by Andreas Osberghaus on 06.09.22.
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SnabbleSDK

extension SnabbleSDK.Config {
    static var appId: String {
        "snabble-sdk-demo-app-oguh3x"
    }
    static var production: Self {
        .init(
            appId: appId,
            secret: "2TKKEG5KXWY6DFOGTZKDUIBTNIRVCYKFZBY32FFRUUWIUAFEIBHQ====",
            environment: .production
        )
    }

    static var staging: Self {
        .init(
            appId: appId,
            secret: "P3SZXAPPVAZA5JWYXVKFSGGBN4ZV7CKCWJPQDMXSUMNPZ5IPB6NQ====",
            environment: .staging
        )
    }

    static var testing: Self {
        .init(
            appId: appId,
            secret: "BWXJ2BFC2JRKRNW4QBASQCF2TTANPTVPOXQJM57JDIECZJQHZWOQ====",
            environment: .testing
        )
    }
}
