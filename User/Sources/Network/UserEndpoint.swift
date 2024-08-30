//
//  UserEndpoint.swift
//  
//
//  Created by Andreas Osberghaus on 2024-02-15.
//

import Foundation
import SnabbleNetwork

extension Endpoints {
    public enum User {
        public static func me() -> Endpoint<SnabbleUser.User> {
            return .init(
                path: "/apps/users/me",
                method: .get(nil),
                parse: { data in
                    let userDto = try Endpoints.jsonDecoder.decode(UserDTO.self, from: data)
                    return .fromDTO(userDto)
                }
            )
        }
        
        public static func update(details: SnabbleUser.User.Details) -> Endpoint<Void> {
            return .init(
                path: "/apps/users/me/details",
                method: .put(try? Endpoints.jsonEncoder.encode(details.toDTO())),
                parse: { _ in
                    return ()
                }
            )
        }
        
        public static func update(consent: SnabbleUser.User.Consent) -> Endpoint<Void> {
            return .init(
                path: "/apps/users/me/consents",
                method: .post(try? Endpoints.jsonEncoder.encode(consent.toDTO())),
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
