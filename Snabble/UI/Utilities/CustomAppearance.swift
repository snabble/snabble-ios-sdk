//
//  CustomAppearance.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//
//  "Chameleon mode" support

public protocol CustomAppearance {
    var buttonBackgroundColor: UIColor { get }
    var buttonTextColor: UIColor { get }
    var titleIcon: UIImage? { get }
}

public protocol CustomizableAppearance: class {
    func setCustomAppearance(_ appearance: CustomAppearance)
}

extension UIButton: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.backgroundColor = appearance.buttonBackgroundColor
        self.tintColor = appearance.buttonTextColor
    }
}
