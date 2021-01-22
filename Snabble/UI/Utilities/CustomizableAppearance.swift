//
//  CustomizableAppearance.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 22.01.21.
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
