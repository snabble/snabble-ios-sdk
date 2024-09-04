//
//  User+Defaults.swift
//  PhoneAuth
//
//  Created by Uwe Tilemann on 13.03.24.
//

import Foundation

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
