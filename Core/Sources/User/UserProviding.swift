//
//  UserProviding.swift
//  SnabbleCore
//
//  Created by Andreas Osberghaus on 2024-09-05.
//  Moved from SnabbleUser to SnabbleCore on 2026-03-27 to avoid circular dependency
//

import Foundation

/// Protocol for providing user information
///
/// - Note: The concrete `User` type is defined in SnabbleUser module.
///         This protocol uses type erasure (Any) to avoid circular dependencies.
public protocol UserProviding: AnyObject {
    /// Providing a user
    /// - Returns: The user object for the app (User type from SnabbleUser module)
    func getUser() -> Any?
}
