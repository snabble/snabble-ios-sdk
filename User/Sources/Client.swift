//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2024-05-27.
//

import Foundation
import KeychainAccess

public struct Client {
    private static let service = "io.snabble.sdk"

    // MARK: - client id
    private static let idKey = "Snabble.api.clientId"

    /**
     SnabbleSDK client identification

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
    */
    public static var id: String {
        let keychain = Keychain(service: service)

        if let id = keychain[idKey] {
            return id
        }

        if let id = UserDefaults.standard.string(forKey: idKey) {
            keychain[idKey] = id
            return id
        }

        let id = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
        keychain[idKey] = id
        UserDefaults.standard.set(id, forKey: idKey)
        return id
    }
}
