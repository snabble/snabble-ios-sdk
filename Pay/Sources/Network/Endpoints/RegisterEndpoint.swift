//
//  RegisterEndpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import SnabbleLogger

extension Endpoints {
    enum Register {
        static func post(apiKeyValue: String, onEnvironment environment: Environment = .production) -> Endpoint<Credentials> {
            Logger.shared.debug("Uses apiKey: \(apiKeyValue)")
            var endpoint: Endpoint<Credentials> = .init(path: "/apps/register", method: .post(nil), environment: environment)
            endpoint.headerFields.updateValue(apiKeyValue, forKey: "snabblePayKey")
            return endpoint
        }
    }
}
