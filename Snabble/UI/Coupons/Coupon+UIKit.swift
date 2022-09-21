//
//  Coupon+UIKit.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit
import SnabbleCore

extension Coupon {
    var backgroundColor: UIColor? {
        UIColor(rgbString: colors?.background ?? "ffffff")
    }

    var textColor: UIColor? {
        UIColor(rgbString: colors?.foreground ?? "000000")
    }
}
