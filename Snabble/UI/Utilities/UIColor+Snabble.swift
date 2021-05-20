//
//  UIColor+Snabble.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static var shadowColor = UIColor(rgbaValue: 0x2222223f)

    static var borderColor: UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor(rgbaValue: 0x00000019)
        }

        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(rgbaValue: 0xFFFFFF19)
            }

            return UIColor(rgbaValue: 0x00000019)
        }
    }
}
