//
//  RegisterEndpoint.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-12.
//

import Foundation
import SnabbleLogger
import SnabbleNetwork

extension Endpoints {
    enum Register {
        static func post(apiKeyValue: String, onEnvironment environment: Environment = .production) -> Endpoint<Credentials> {
            Logger.shared.debug("Uses apiKey: \(apiKeyValue)")
            return Endpoint(
                path: "/apps/register",
                method: .post(nil),
                parse: { try Endpoints.jsonDecoder.decode(Credentials.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL, additionalHeaderFields: ["snabblePayKey": apiKeyValue])
        }
    }
}
