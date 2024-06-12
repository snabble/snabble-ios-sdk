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
    // if the hosting app uses https://github.com/sindresorhus/Defaults there is a restriction:
    // `The key name must be ASCII, not start with @, and cannot contain a dot (.).`
    var isSignedInKey: String {
        "io-snabble-sdk-network-user-isSignedIn"
    }
    func isUserSignedIn() -> Bool {
        return bool(forKey: isSignedInKey)
    }
    func setUserSignedIn(_ signedIn: Bool) {
        setValue(signedIn, forKey: isSignedInKey)
    }
}

extension SnabbleNetwork.User {
    func update(withDetails details: SnabbleNetwork.User.Details) {
        print("TODO: SnabbleNetwork.User update(withDetails:)")
//        UserDefaults.standard.setUser(.init(user: self, details: details))
    }
    func update(withConsent consent: SnabbleNetwork.User.Consent) {
        print("TODO: SnabbleNetwork.User update(withConsent:)")
//        UserDefaults.standard.setUser(.init(user: self, consent: consent))
    }
}
