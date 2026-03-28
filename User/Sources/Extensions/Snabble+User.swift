//
//  Snabble+User.swift
//  SnabbleUser
//
//  Created by Uwe Tilemann on 2026-03-27.
//  Moved from Core to User to resolve circular dependency
//

import Foundation
import SnabbleCore
import SnabbleNetwork

extension Snabble {
    /**
     SnabbleSDK client identification

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
    */
    public static var clientId: String {
        SnabbleCore.Client.id
    }

    // MARK: - app user id

    /**
     SnabbleSDK application user identification

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
    */
    public var appUser: AppUser? {
        get {
            AppUser.get(forConfig: config)
        }
        set {
            AppUser.set(newValue, forConfig: config)
            tokenRegistry.invalidate()
            OrderList.clearCache()
        }
    }
}
