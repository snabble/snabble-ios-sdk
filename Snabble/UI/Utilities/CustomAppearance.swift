//
//  CustomAppearance.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//
//  "Chameleon mode" support

public struct CustomAppearance {
    public let backgroundColor: UIColor
    public let buttonBackgroundColor: UIColor
    public let buttonTextColor: UIColor
    public let titleIcon: UIImage

    public init(backgroundColor: UIColor, buttonBackgroundColor: UIColor, buttonTextColor: UIColor, titleIcon: UIImage) {
        self.backgroundColor = backgroundColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.buttonTextColor = buttonTextColor
        self.titleIcon = titleIcon
    }
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
