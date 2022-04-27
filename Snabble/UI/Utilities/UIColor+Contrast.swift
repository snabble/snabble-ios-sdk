//
//  UIColor+Contrast.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit
import WCAG_Colors

extension UIColor {
    static var contrasts: [UIColor]?
}

public extension UIColor {
    var contrast: UIColor? {
        guard let contrasts = Self.contrasts, !contrasts.isEmpty else {
            return Self.getTextColor(onBackgroundColor: self)
        }

        guard contrasts.count > 1 else {
            return contrasts.first
        }
        
        return Self.getTextColor(
            fromColors: contrasts,
            withFont: .preferredFont(forTextStyle: .body), // default Font
            onBackgroundColor: self
        )
    }
}
