//
//  UserProviding.swift
//  
//
//  Created by Andreas Osberghaus on 2024-09-05.
//

import Foundation

public protocol UserProviding: AnyObject {
    /// Providing an user
    /// - Returns: The user object for the app
    func getUser() -> User?
}
