//
//  SnabbleAppUser.swift
//
//
//  Created by Uwe Tilemann on 15.05.24.
//

import Foundation
import KeychainAccess

public class SnabbleAppUser {
    private static let service = "io.snabble.sdk"

    private let config: Configuration
    
    public init(config: Configuration) {
        self.config = config
    }

    // MARK: - app user id
    private var appUserKey: String {
        "Snabble.api.appUserId.\(config.domainName).\(config.appId)"
    }
    
    public static func appUser(forConfig config: Configuration) -> AppUser? {
        SnabbleAppUser(config: config).appUser
    }

    /**
     SnabbleSDK application user identification

     Stored in the keychain. Survives an uninstallation

     - Important: [Apple Developer Forum Thread 36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
    */
    public var appUser: AppUser? {
        get {
            let keychain = Keychain(service: Self.service)
            guard let stringRepresentation = keychain[appUserKey] else {
                return nil
            }
            return AppUser(stringRepresentation: stringRepresentation)
        }

        set {
            let keychain = Keychain(service: Self.service)
            keychain[appUserKey] = newValue?.stringRepresentation
            UserDefaults.standard.set(newValue?.id, forKey: "Snabble.api.appUserId")
        }
    }
    
    public static func user(forConfig config: Configuration) -> User? {
        SnabbleAppUser(config: config).user
    }
    
    public var user: User? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "Snabble.user") else { return nil }
            let jsonDecoder = JSONDecoder()
            do {
                return try jsonDecoder.decode(User.self, from: data)
            } catch {
                return nil
            }
        }
        set {
            let jsonEncoder = JSONEncoder()
            do {
                let encoded = try jsonEncoder.encode(newValue)
                UserDefaults.standard.set(encoded, forKey: "Snabble.user")
            } catch {
                UserDefaults.standard.set(nil, forKey: "Snabble.user")
            }
        }
    }
}
