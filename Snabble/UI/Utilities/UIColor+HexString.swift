//
//  UIColor+HexString.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(rgbString: String) {
        var rgb = rgbString

        // strip leading `#`
        if rgb.hasPrefix("#") {
            rgb = String(rgb.dropFirst())
        }

        // convert 3-digit CSS value to 6 digits,
        // e.g. `123` to `112233`
        if rgb.count == 3 {
            rgb = rgb.reduce(into: "") {
                $0.append($1)
                $0.append($1)
            }
        }

        let rgbValue = UInt32(rgb, radix: 16) ?? 0
        let byte: UInt32 = 0xFF

        let red = (rgbValue >> 16) & byte
        let green = (rgbValue >> 8) & byte
        let blue = rgbValue & byte

        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
}
