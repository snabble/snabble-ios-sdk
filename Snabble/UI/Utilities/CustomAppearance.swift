//
//  CustomAppearance.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//
//  "Chameleon mode" support

public protocol CustomAppearance {
    var primaryColor: UIColor { get }
    var backgroundColor: UIColor { get }

    var buttonBorderColor: UIColor { get }
    var buttonShadowColor: UIColor { get }
    var buttonBackgroundColor: UIColor { get }
    var buttonTextColor: UIColor { get }

    var stepperButtonBackgroundColor: UIColor { get }

    var titleIcon: UIImage? { get }
}

public protocol CustomizableAppearance: AnyObject {
    func setCustomAppearance(_ appearance: CustomAppearance)
}

extension UIButton: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.backgroundColor = appearance.buttonBackgroundColor
        self.tintColor = appearance.buttonTextColor
    }
}
