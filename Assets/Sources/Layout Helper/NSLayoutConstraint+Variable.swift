//
//  NSLayoutConstraint+Variable.swift
//  
//
//  Created by Andreas Osberghaus on 23.09.21.
//

import Foundation
import UIKit

extension NSLayoutConstraint {
    /// Returns the constraint sender after setting the variable.
    ///
    /// - Parameter variable: The variable to be set.
    /// - Returns: The sent constraint.
    public func usingVariable(_ variable: inout NSLayoutConstraint?) -> Self {
        variable = self
        return self
    }
}
