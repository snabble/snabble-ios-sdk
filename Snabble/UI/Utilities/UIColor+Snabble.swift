//
//  UIColor+Snabble.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static var shadowColor = UIColor(rgbaValue: 0x2222223f) // rgba(34, 34, 34, 0.2470588235)

    static var borderColor: UIColor {
        guard #available(iOS 13.0, *) else {
            return UIColor(rgbaValue: 0x00000019) // rgba(0, 0, 0, 0.09803921569)
        }

        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(rgbaValue: 0xFFFFFF19) // rgba(1, 1, 1, 0.09803921569)
            }

            return UIColor(rgbaValue: 0x00000019) // rgba(0, 0, 0, 0.09803921569)
        }
    }
}
