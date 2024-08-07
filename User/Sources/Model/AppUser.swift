//
//  AppUser.swift
//
//
//  Created by Uwe Tilemann on 15.05.24.
//

import Foundation
import KeychainAccess

/// SnabbleSDK application user identification
///
/// A plain text username and password combination.
/// - Important: It contains a sensitve data. Be careful when you store it.
public struct AppUser: Codable {
    /// the `identifier` of the `AppUser`
    public let id: String

    /// an opaque information for the backend
    public let secret: String

    /// A formatted string that specifies the components of the `AppUserId`.
    ///
    /// The string representation always has two components separated by a colon. The first is the `value` and last is the `secret`
    public var stringRepresentation: String {
        "\(id):\(secret)"
    }

    /// initialize an `AppUserId` with a received `value` and `secret`
    /// - Parameters:
    ///   - value: the actual information of the `userId`
    ///   - secret: an opaque information for the backend
    public init(id: String, secret: String) {
        self.id = id
        self.secret = secret
    }

    /**
     An optional initializer with a valid `stringRepresentation` value

     `value` and `secret` must be separated by a colon.

     - Precondition:
        - `value` is the first part and `secret` the second.
        - Only two elements allowed after split by colon
     */
    public init?(stringRepresentation: String) {
        let components = stringRepresentation.split(separator: ":")
        guard components.count == 2 else {
            return nil
        }

        id = String(components[0])
        secret = String(components[1])
    }
}

extension AppUser {
    private static let service = "io.snabble.sdk"
    
    // MARK: - app user id
    private static func appUserKey(forConfig config: Configuration) -> String {
        "Snabble.api.appUserId.\(config.domainName).\(config.appId)"
    }
    
    public static func get(forConfig config: Configuration) -> AppUser? {
        let keychain = Keychain(service: Self.service)
        guard let stringRepresentation = keychain[appUserKey(forConfig: config)] else {
            return nil
        }
        return AppUser(stringRepresentation: stringRepresentation)
    }
    
    public static func set(_ appUser: AppUser?, forConfig config: Configuration) {
        let keychain = Keychain(service: Self.service)
        keychain[appUserKey(forConfig: config)] = appUser?.stringRepresentation
        UserDefaults.standard.set(appUser?.id, forKey: "Snabble.api.appUserId")
    }
}
