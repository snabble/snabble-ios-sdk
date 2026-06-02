//
//  Snabble+AppUser.swift
//  SnabbleCore
//
//  Created by Uwe Tilemann on 2026-03-27.
//  Internal AppUser access for Core module
//

import Foundation
import SnabbleNetwork

// Declare conformance to SnabbleNetwork.Configurable here to avoid circular dependency
extension Config: SnabbleNetwork.Configurable {}

extension Snabble {
    // MARK: - app user id (internal for Core module)

    /**
     SnabbleSDK application user identification (internal accessor)

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)

     - Note: This is an internal accessor. The public API is in SnabbleUser module.
    */
    internal var appUser: AppUser? {
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
