//
//  UIColor+Contrast.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit
import WCAG_Colors

public extension UIColor {
    var contrast: UIColor? {
        Self.getTextColor(onBackgroundColor: self)
    }
}
