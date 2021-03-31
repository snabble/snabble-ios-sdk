//
//  NSLayoutConstraint+Identifier.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit

extension NSLayoutConstraint {
    /// Returns the constraint sender with the passed identifier.
    ///
    /// - Parameter identifier: The identifier to be set.
    /// - Returns: The sent constraint adjusted with the new priority.
    func usingIdentifier(_ identifier: String) -> Self {
        self.identifier = identifier
        return self
    }
}

extension Array where Element: NSLayoutConstraint {
    /// Returns a constraint with the passed identifier.
    ///
    /// - Parameter identifier: The identifier to be searched.
    /// - Returns: The first constraint with the identifier
    func first(with identifier: String) -> Element? {
        first(where: { constraint in
            constraint.identifier == identifier
        })
    }
}
