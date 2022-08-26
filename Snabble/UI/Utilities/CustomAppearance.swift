//
//  CustomAppearance.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//
//  "Chameleon mode" support

import UIKit

public protocol CustomAppearance {
    var accent: UIColor { get }
    var onAccent: UIColor { get }
    var titleIcon: UIImage? { get }
}
