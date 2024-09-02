//
//  User+Defaults.swift
//  PhoneAuth
//
//  Created by Uwe Tilemann on 13.03.24.
//

import Foundation
import SnabbleUser
import SnabbleCore

public extension UserDefaults {
    static var isSignedInKey: String {
        "io-snabble-sdk-network-user-isSignedIn"
    }

    func isUserSignedIn() -> Bool {
        bool(forKey: Self.isSignedInKey)
    }

    func setUserSignedIn(_ signedIn: Bool) {
        setValue(signedIn, forKey: Self.isSignedInKey)
    }
}

public extension SnabbleUser.User {    
    func update(withDetails details: User.Details) {
        let user = SnabbleUser.User(user: self, details: details)
        Snabble.shared.user = user
    }

    func update(withConsent consent: User.Consent) {
        let user = SnabbleUser.User(user: self, consent: consent)
        Snabble.shared.user = user
    }
}
