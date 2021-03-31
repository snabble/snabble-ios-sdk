//
//  UIColor+Contrast.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit
import Capable

extension UIColor {
    static var contrasts: [UIColor]?
    static var defaultContrast: UIColor { .white }
}

public extension UIColor {
    var contrast: UIColor {
        guard let contrasts = Self.contrasts, !contrasts.isEmpty else {
            return Self.getTextColor(onBackgroundColor: self) ?? .defaultContrast
        }
        return Self.getTextColor(
            fromColors: contrasts,
            withFont: .systemFont(ofSize: 17), // default Font
            onBackgroundColor: self
        ) ?? contrasts.first ?? .defaultContrast
    }
}
