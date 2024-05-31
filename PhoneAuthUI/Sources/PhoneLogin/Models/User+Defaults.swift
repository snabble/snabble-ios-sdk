//
//  User+Defaults.swift
//  teo
//
//  Created by Uwe Tilemann on 13.03.24.
//

import Foundation
import SnabbleNetwork
//import Defaults

private extension UserDefaults {
    private var userKey: String {
        "io.snabble.sdk.network.user"
    }
    
    func user() -> SnabbleNetwork.User? {
        guard object(forKey: userKey) != nil else {
            return nil
        }
        return object(forKey: userKey)
    }
    
    func setUser(_ user: SnabbleNetwork.User?) {
        setValue(user, forKey: userKey)
    }
}

private extension UserDefaults {
    private var isSignedInKey: String {
        "io.snabble.sdk.network.user.isSignedIn"
    }
    func isUserSignedIn() -> Bool {
        return bool(forKey: isSignedInKey)
    }
}

//extension Defaults.Keys {
//    static let user = Key<SnabbleNetwork.User?>("User", default: nil)
//    static let isSignedIn = Key<Bool>("isSignedIn", default: false)
//}

extension SnabbleNetwork.User: Defaults.Serializable {}

extension SnabbleNetwork.User {
    func update(withDetails details: User.Details) {
        UserDefauls.standard.setUser(.init(user: self, details: details))
    }
    func update(withConsent consent: User.Consent) {
        UserDefauls.standard.setUser(.init(user: self, consent: consent))
    }
}
