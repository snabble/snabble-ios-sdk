//
//  NSLayoutConstraint+Priority.swift
//  
//
//  Created by Andreas Osberghaus on 23.09.21.
//

import Foundation
import UIKit

extension NSLayoutConstraint {
    /// Returns the constraint sender with the passed priority.
    ///
    /// - Parameter priority: The priority to be set.
    /// - Returns: The sent constraint adjusted with the new priority.
    public func usingPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }

    public func usingPriority(_ number: Float) -> Self {
        self.priority = .init(number)
        return self
    }
}
