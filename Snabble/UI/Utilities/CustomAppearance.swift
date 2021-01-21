//
//  CustomAppearance.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//
//  "Chameleon mode" support

public protocol CustomAppearance {
    var accentColor: UIColor { get }
    var accentContrastColor: UIColor { get }

    var titleIcon: UIImage? { get }
}

public extension CustomAppearance {
    var accentColor: UIColor { UIColor(rgbValue: 0x0077bb) }
    var accentContrastColor: UIColor { .white }

    var titleIcon: UIImage? { nil }
}

public protocol CustomizableAppearance: AnyObject {
    func setCustomAppearance(_ appearance: CustomAppearance)
}

extension UIButton: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.backgroundColor = appearance.accentColor
        self.tintColor = appearance.accentContrastColor
    }
}
