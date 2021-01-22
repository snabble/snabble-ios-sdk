//
//  CustomAppearance.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//
//  "Chameleon mode" support

import UIKit

public protocol CustomAppearance {
    var accentColor: UIColor { get }
    var titleIcon: UIImage? { get }

    var contrastColors: [UIColor]? { get }
}

public extension CustomAppearance {
    var accentColor: UIColor { UIColor(rgbValue: 0x0077bb) }
    var titleIcon: UIImage? { nil }
    var contrastColors: [UIColor]? { nil }
}
