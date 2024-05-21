//
//  UserEndpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2024-02-15.
//

import Foundation

extension Endpoints {
    public enum User {
        public static func me() -> Endpoint<SnabbleNetwork.User> {
            return .init(
                path: "/apps/users/me",
                method: .get(nil),
                parse: { data in
                    try Endpoints.jsonDecoder.decode(SnabbleNetwork.User.self, from: data)
                }
            )
        }
        
        public static func update(details: SnabbleNetwork.User.Details) -> Endpoint<Void> {
            return .init(
                path: "/apps/users/me/details",
                method: .put(try? Endpoints.jsonEncoder.encode(details)),
                parse: { _ in
                    return ()
                }
            )
        }
        public static func update(consent: SnabbleNetwork.User.Consent) -> Endpoint<Void> {
            
            return .init(
                path: "/apps/users/me/consents",
                method: .post(try? Endpoints.jsonEncoder.encode(consent)),
                parse: { _ in
                    return ()
                }
            )
        }

        public static func erase() -> Endpoint<Void> {
            return .init(
                path: "/apps/users/me/erase",
                method: .post(nil),
                parse: { _ in
                    return ()
                }
            )
        }
    }
}
