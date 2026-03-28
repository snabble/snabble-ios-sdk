//
//  UserProviding.swift
//  SnabbleUser
//
//  Created by Andreas Osberghaus on 2024-09-05.
//  Extended on 2026-03-27 to work with Core's type-erased version
//

import Foundation
import SnabbleCore

// Re-export Core's UserProviding for consistency
// The Core version uses Any? to avoid circular dependencies
public typealias UserProvidingBase = SnabbleCore.UserProviding

/// User-specific extension of UserProviding with concrete User type
public protocol UserProviding: UserProvidingBase {
    /// Providing a user
    /// - Returns: The user object for the app
    func getUser() -> User?
}
