//
//  CustomAppearance.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//
//  "Chameleon mode" support

public struct CustomAppearance {
    public let buttonBackgroundColor: UIColor
    public let buttonTextColor: UIColor
    public let titleIcon: UIImage?

    public init(buttonBackgroundColor: UIColor, buttonTextColor: UIColor, titleIcon: UIImage? = nil) {
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
