//
//  Appearance.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 06.08.22.
//

import Foundation
import SwiftUI

public struct Appearance: Codable {
    let accent: String?
    let secondaryAccent: String?
    let contrast: String?

    static let shared: Appearance =  load("Appearance.json")
}

extension  SwiftUI.Color {
    static var accentColor:  SwiftUI.Color { .black }
    static var buttonTextColor:  SwiftUI.Color { .white }
}

public extension Appearance {

    var accentColor: SwiftUI.Color {
        guard let string = accent else {
            return Color.accentColor
        }

        return Assets.color(named: string) ?? Color.accentColor
    }

    var secondaryAccentColor:  SwiftUI.Color {
        guard let string = secondaryAccent else {
            return Color.accentColor
        }

        return Assets.color(named: string) ?? Color.accentColor
    }

    var buttonTextColor:  SwiftUI.Color {
        return SwiftUI.Color.buttonTextColor
    }
}
