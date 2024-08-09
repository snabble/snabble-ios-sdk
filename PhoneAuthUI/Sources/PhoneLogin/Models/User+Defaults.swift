//
//  User+Defaults.swift
//  teo
//
//  Created by Uwe Tilemann on 13.03.24.
//

import Foundation
import SnabbleNetwork
import SnabbleUser

public extension UserDefaults {
    private static var isSignedInKey: String {
        "io-snabble-sdk-network-user-isSignedIn"
    }

    func isUserSignedIn() -> Bool {
        bool(forKey: Self.isSignedInKey)
    }

    func setUserSignedIn(_ signedIn: Bool) {
        setValue(signedIn, forKey: Self.isSignedInKey)
    }
}

public extension SnabbleNetwork.User {
    static var userKey: String {
        "io-snabble-sdk-network-user"
    }
    
    static var current: Self? {
        UserDefaults.standard.value(forKey: Self.userKey) as? SnabbleNetwork.User
    }
    
    static func delete() {
        UserDefaults.standard.setValue(nil, forKey: Self.userKey)
    }
    
    func update(withDetails details: SnabbleNetwork.User.Details) {
        let user = SnabbleNetwork.User(user: self, details: details)
        UserDefaults.standard.setValue(user, forKey: Self.userKey)
    }

    func update(withConsent consent: SnabbleNetwork.User.Consent) {
        let user = SnabbleNetwork.User(user: self, consent: consent)
        UserDefaults.standard.setValue(user, forKey: Self.userKey)
    }
}
