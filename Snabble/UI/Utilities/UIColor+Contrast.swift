//
//  UIColor+Contrast.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 22.01.21.
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
        guard let contrasts = Self.contrasts else {
            return Self.getTextColor(onBackgroundColor: self) ?? .defaultContrast
        }
        return Self.getTextColor(fromColors: contrasts, withFont: .systemFont(ofSize: 17), onBackgroundColor: self) ?? .defaultContrast
    }
}
