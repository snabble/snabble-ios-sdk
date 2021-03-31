//
//  CustomizableAppearance.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation
import UIKit

public protocol CustomizableAppearance: AnyObject {
    func setCustomAppearance(_ appearance: CustomAppearance)
}

extension UIButton: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        backgroundColor = appearance.accentColor
        tintColor = appearance.accentColor.contrast
    }
}
