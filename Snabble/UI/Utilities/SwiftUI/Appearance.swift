//
//  Appearance.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 06.08.22.
//

import Foundation

public struct Appearance: Codable {
    let accent: String?
    let secondaryAccent: String?
    let contrast: String?

    static let shared : Appearance = load("Appearance.json")
}

#if canImport(SwiftUI)
import SwiftUI

public struct AccentColors {
    public static let accentColor = Color(.red)
    public static let buttonTextColor = Color(.white)
}

public extension Appearance {

    var accentColor: Color {
        guard let string = accent else {
            return AccentColors.accentColor
        }

        return Color(OSColor(rgbString: string))
    }

    var buttonTextColor: Color {
        return AccentColors.buttonTextColor
    }
}
#endif
