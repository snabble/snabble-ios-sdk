//
//  UIColor+HEX.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(rgbaValue: UInt32) {
        let byte: UInt32 = 0xff
        let red = CGFloat((rgbaValue >> 24) & byte) / 255.0
        let green = CGFloat((rgbaValue >> 16) & byte) / 255.0
        let blue = CGFloat((rgbaValue >> 8) & byte) / 255.0
        let alpha = CGFloat((rgbaValue) & byte) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    convenience init(rgbValue: UInt32) {
        let byte: UInt32 = 0xff
        let red = CGFloat((rgbValue >> 16) & byte) / 255.0
        let green = CGFloat((rgbValue >> 8) & byte) / 255.0
        let blue = CGFloat((rgbValue) & byte) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
