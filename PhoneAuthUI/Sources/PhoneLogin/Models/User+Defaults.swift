//
//  User+Defaults.swift
//  teo
//
//  Created by Uwe Tilemann on 13.03.24.
//

import Foundation
import SnabbleNetwork
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

public extension SnabbleNetwork.User {    
    static func delete() {
        Snabble.shared.user = nil
    }
    
    func update(withDetails details: SnabbleNetwork.User.Details) {
        let networkUser = SnabbleNetwork.User(user: self, details: details)
        Snabble.shared.user = .init(user: networkUser)
    }

    func update(withConsent consent: SnabbleNetwork.User.Consent) {
        let networkUser = SnabbleNetwork.User(user: self, consent: consent)
        Snabble.shared.user = .init(user: networkUser)
    }
}
