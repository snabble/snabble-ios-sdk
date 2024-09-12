//
//  Asset+Color.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.08.22.
//

import Foundation
import UIKit
import WCAG_Colors

private extension UIColor {
    var contrast: UIColor? {
        Self.getTextColor(onBackgroundColor: self)
    }
}

extension UIColor {
    // MARK: - Snabble Colors

    public static func named(_ name: String, domain: Any? = Asset.domain) -> UIColor? {
        Asset.color(named: name, domain: domain)
    }

    public static func border(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "border", domain: domain) ?? .systemGray
    }

    public static func shadow(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "shadow", domain: domain) ?? .systemGray3
    }
    
    public static func projectPrimary(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "primary", domain: domain) ?? UIColor(red: 0, green: 119.0 / 255.0, blue: 187.0 / 255.0, alpha: 1)
    }
    
    public static func onProjectPrimary(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "onPrimary", domain: domain) ?? .label
    }
    
    public static func projectSecondary(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "secondary", domain: domain) ?? UIColor(red: 0, green: 119.0 / 255.0, blue: 187.0 / 255.0, alpha: 1)
    }
    
    public static func onProjectSecondary(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "onSecondary", domain: domain) ?? .secondaryLabel
    }

    public static func systemGreen(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "systemGreen", domain: domain) ?? .systemGreen
    }
    public static func systemRed(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "systemRed", domain: domain) ?? .systemRed
    }
}

import SwiftUI
extension SwiftUI.Color {
    private static func color(_ uiColor: UIColor) -> SwiftUI.Color {
        if #available(iOS 15.0, *) {
            return Self(uiColor: uiColor)
        } else {
            return Self(uiColor)
        }
    }
}

extension SwiftUI.Color {
    // MARK: - Snabble Colors

    public static func named(_ name: String, domain: Any? = Asset.domain) -> SwiftUI.Color? {
        guard let uiColor = UIColor.named(name, domain: domain) else {
            return nil
        }
        return color(uiColor)
    }

    public static func border(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.border(in: domain))
    }

    public static func shadow(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.shadow(in: domain))
    }
    
    public static func projectPrimary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.projectPrimary(in: domain))
    }
    
    public static func onProjectPrimary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.onProjectPrimary(in: domain))
    }
    
    public static func projectSecondary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.projectSecondary(in: domain))
    }
    
    public static func onProjectSecondary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.onProjectSecondary(in: domain))
    }

    public static func systemGreen(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.systemGreen(in: domain))
    }
    public static func systemRed(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.systemRed(in: domain))
    }
}

public extension SwiftUI.Color {
    // MARK: - Semantic Colors

    static var label: SwiftUI.Color {
        color(.label)
    }

    static var secondaryLabel: SwiftUI.Color {
        color(.secondaryLabel)
    }

    static var tertiaryLabel: SwiftUI.Color {
        color(.tertiaryLabel)
    }

    static var quaternaryLabel: SwiftUI.Color {
        color(.quaternaryLabel)
    }

    static var systemFill: SwiftUI.Color {
        color(.systemFill)
    }

    static var secondarySystemFill: SwiftUI.Color {
        color(.secondarySystemFill)
    }

    static var tertiarySystemFill: SwiftUI.Color {
        color(.tertiarySystemFill)
    }

    static var quaternarySystemFill: SwiftUI.Color {
        color(.quaternarySystemFill)
    }

    static var placeholderText: SwiftUI.Color {
        color(.placeholderText)
    }

    @available(iOS 15.0, *)
    static var tintColor: SwiftUI.Color {
        color(.tintColor)
    }

    static var systemBackground: SwiftUI.Color {
        color(.systemBackground)
    }

    static var secondarySystemBackground: SwiftUI.Color {
        color(.secondarySystemBackground)
    }

    static var tertiarySystemBackground: SwiftUI.Color {
        color(.tertiarySystemBackground)
    }

    static var systemGroupedBackground: SwiftUI.Color {
        color(.systemGroupedBackground)
    }

    static var secondarySystemGroupedBackground: SwiftUI.Color {
        color(.secondarySystemGroupedBackground)
    }

    static var tertiarySystemGroupedBackground: SwiftUI.Color {
        color(.tertiarySystemGroupedBackground)
    }

    static var separator: SwiftUI.Color {
        color(.separator)
    }

    static var opaqueSeparator: SwiftUI.Color {
        color(.opaqueSeparator)
    }

    static var link: SwiftUI.Color {
        color(.link)
    }

    static var darkText: SwiftUI.Color {
        color(.darkText)
    }

    static var lightText: SwiftUI.Color {
        color(.lightText)
    }

    static var systemBlue: SwiftUI.Color {
        color(.systemBlue)
    }

    static var systemBrown: SwiftUI.Color {
        color(.systemBrown)
    }

    @available(iOS 15.0, *)
    static var systemCyan: SwiftUI.Color {
        color(.systemCyan)
    }

    static var systemGreen: SwiftUI.Color {
        systemGreen()
    }

    static var systemIndigo: SwiftUI.Color {
        color(.systemIndigo)
    }

    @available(iOS 15.0, *)
    static var systemMint: SwiftUI.Color {
        color(.systemMint)
    }

    static var systemOrange: SwiftUI.Color {
        color(.systemOrange)
    }

    static var systemPink: SwiftUI.Color {
        color(.systemPink)
    }

    static var systemPurple: SwiftUI.Color {
        color(.systemPurple)
    }

    static var systemRed: SwiftUI.Color {
        systemRed()
    }

    static var systemTeal: SwiftUI.Color {
        color(.systemTeal)
    }

    static var systemYellow: SwiftUI.Color {
        color(.systemYellow)
    }

    static var systemGray: SwiftUI.Color {
        color(.systemGray)
    }

    static var systemGray2: SwiftUI.Color {
        color(.systemGray2)
    }

    static var systemGray3: SwiftUI.Color {
        color(.systemGray3)
    }

    static var systemGray4: SwiftUI.Color {
        color(.systemGray4)
    }

    static var systemGray5: SwiftUI.Color {
        color(.systemGray5)
    }

    static var systemGray6: SwiftUI.Color {
        color(.systemGray6)
    }

    static var lightGray: SwiftUI.Color {
        color(.lightGray)
    }

    static var darkGray: SwiftUI.Color {
        color(.darkGray)
    }

    static var magenta: SwiftUI.Color {
        color(.magenta)
    }
}
