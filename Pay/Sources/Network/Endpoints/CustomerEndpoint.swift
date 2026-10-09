//
//  CustomerEndpoint.swift
//
//
//  Created by Andreas Osberghaus on 2023-03-16.
//

import Foundation
import SnabbleNetwork

extension Endpoints {
    public enum Customer {
        public static func put(id: String?, loyaltyId: String?, onEnvironment environment: Environment = .production) -> Endpoint<SnabblePayNetwork.Customer> {
            Endpoint(
                path: "/apps/customer",
                method: .put(
                    data(forId: id, loyaltyId: loyaltyId)
                ),
                parse: { try Endpoints.jsonDecoder.decode(SnabblePayNetwork.Customer.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        public static func delete(onEnvironment environment: Environment = .production) -> Endpoint<SnabblePayNetwork.Customer> {
            Endpoint(
                path: "/apps/customer",
                method: .delete,
                parse: { try Endpoints.jsonDecoder.decode(SnabblePayNetwork.Customer.self, from: $0) }
            ).with(baseURLOverride: environment.baseURL)
        }

        // swiftlint:disable force_try
        private static func data(forId id: String?, loyaltyId: String?) -> Data {
            let jsonObject = [
                "id": id,
                "loyaltyId": loyaltyId
            ]
            return try! JSONSerialization.data(withJSONObject: jsonObject)
        }
        // swiftlint:enable force_try
    }
}
