//
//  Coupon+UIKit.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit
import SnabbleCore
import SnabbleComponents

extension Coupon {
    var backgroundColor: UIColor? {
        UIColor(hex: colors?.background ?? "#ffffff")
    }

    var textColor: UIColor? {
        UIColor(hex: colors?.foreground ?? "#000000")
    }
}
