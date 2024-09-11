//
//  Theme.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-09-11.
//

import SwiftUI
import UIKit

public enum Theme: Equatable {
    case none
    case project(id: String)
}

public struct ThemeTrait: UITraitDefinition {
    public static var defaultValue: Theme = .none
    public static var affectsColorAppearance: Bool = true
    public static var identifier: String = "io.snabble.theme"
    public static var name: String = "Theme"
}


public struct ThemeKey: EnvironmentKey {
    public static var defaultValue: Theme = ThemeTrait.defaultValue
}

extension ThemeKey: UITraitBridgedEnvironmentKey {
    public static func read(from traitCollection: UITraitCollection) -> Theme {
        traitCollection.theme
    }
    
    public static func write(to mutableTraits: inout any UIMutableTraits, value: Theme) {
        mutableTraits.theme = value
    }
}

extension UITraitCollection {
    var theme: Theme { self[ThemeTrait.self] }
}

extension UIMutableTraits {
    var theme: Theme {
        get {
            self[ThemeTrait.self]
        }
        set {
            self[ThemeTrait.self] = newValue
        }
    }
}
