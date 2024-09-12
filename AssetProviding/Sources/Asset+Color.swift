//
//  Asset+Color.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.08.22.
//

import Foundation
import UIKit
import WCAG_Colors
import SwiftUI

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

extension SwiftUI.Color {
    // MARK: - Snabble Colors

    public static func named(_ name: String, domain: Any? = Asset.domain) -> SwiftUI.Color? {
        guard let uiColor = UIColor.named(name, domain: domain) else {
            return nil
        }
        return .init(uiColor: (uiColor))
    }
    
    public static func border(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.border(in: domain))
    }
    
    public static func shadow(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.shadow(in: domain))
    }
    
    public static func projectPrimary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.projectPrimary(in: domain))
    }
    
    public static func onProjectPrimary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.onProjectPrimary(in: domain))
    }
    
    public static func projectSecondary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.projectSecondary(in: domain))
    }
    
    public static func onProjectSecondary(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.onProjectSecondary(in: domain))
    }

    public static func systemGreen(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.systemGreen(in: domain))
    }
    public static func systemRed(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        .init(uiColor: UIColor.systemRed(in: domain))
    }
}

public extension SwiftUI.Color {
    // MARK: - Semantic Colors

    static var label: SwiftUI.Color {
        .init(uiColor: .label)
    }

    static var secondaryLabel: SwiftUI.Color {
        .init(uiColor: .secondaryLabel)
    }

    static var tertiaryLabel: SwiftUI.Color {
        .init(uiColor: .tertiaryLabel)
    }

    static var quaternaryLabel: SwiftUI.Color {
        .init(uiColor: .quaternaryLabel)
    }

    static var systemFill: SwiftUI.Color {
        .init(uiColor: .systemFill)
    }

    static var secondarySystemFill: SwiftUI.Color {
        .init(uiColor: .secondarySystemFill)
    }

    static var tertiarySystemFill: SwiftUI.Color {
        .init(uiColor: .tertiarySystemFill)
    }

    static var quaternarySystemFill: SwiftUI.Color {
        .init(uiColor: .quaternarySystemFill)
    }

    static var placeholderText: SwiftUI.Color {
        .init(uiColor: .placeholderText)
    }

    @available(iOS 15.0, *)
    static var tintColor: SwiftUI.Color {
        .init(uiColor: .tintColor)
    }

    static var systemBackground: SwiftUI.Color {
        .init(uiColor: .systemBackground)
    }

    static var secondarySystemBackground: SwiftUI.Color {
        .init(uiColor: .secondarySystemBackground)
    }

    static var tertiarySystemBackground: SwiftUI.Color {
        .init(uiColor: .tertiarySystemBackground)
    }

    static var systemGroupedBackground: SwiftUI.Color {
        .init(uiColor: .systemGroupedBackground)
    }

    static var secondarySystemGroupedBackground: SwiftUI.Color {
        .init(uiColor: .secondarySystemGroupedBackground)
    }

    static var tertiarySystemGroupedBackground: SwiftUI.Color {
        .init(uiColor: .tertiarySystemGroupedBackground)
    }

    static var separator: SwiftUI.Color {
        .init(uiColor: .separator)
    }

    static var opaqueSeparator: SwiftUI.Color {
        .init(uiColor: .opaqueSeparator)
    }

    static var link: SwiftUI.Color {
        .init(uiColor: .link)
    }

    static var darkText: SwiftUI.Color {
        .init(uiColor: .darkText)
    }

    static var lightText: SwiftUI.Color {
        .init(uiColor: .lightText)
    }

    static var systemBlue: SwiftUI.Color {
        .init(uiColor: .systemBlue)
    }

    static var systemBrown: SwiftUI.Color {
        .init(uiColor: .systemBrown)
    }

    @available(iOS 15.0, *)
    static var systemCyan: SwiftUI.Color {
        .init(uiColor: .systemCyan)
    }

    static var systemGreen: SwiftUI.Color {
        systemGreen()
    }

    static var systemIndigo: SwiftUI.Color {
        .init(uiColor: .systemIndigo)
    }

    @available(iOS 15.0, *)
    static var systemMint: SwiftUI.Color {
        .init(uiColor: .systemMint)
    }

    static var systemOrange: SwiftUI.Color {
        .init(uiColor: .systemOrange)
    }

    static var systemPink: SwiftUI.Color {
        .init(uiColor: .systemPink)
    }

    static var systemPurple: SwiftUI.Color {
        .init(uiColor: .systemPurple)
    }

    static var systemRed: SwiftUI.Color {
        systemRed()
    }

    static var systemTeal: SwiftUI.Color {
        .init(uiColor: .systemTeal)
    }

    static var systemYellow: SwiftUI.Color {
        .init(uiColor: .systemYellow)
    }

    static var systemGray: SwiftUI.Color {
        .init(uiColor: .systemGray)
    }

    static var systemGray2: SwiftUI.Color {
        .init(uiColor: .systemGray2)
    }

    static var systemGray3: SwiftUI.Color {
        .init(uiColor: .systemGray3)
    }

    static var systemGray4: SwiftUI.Color {
        .init(uiColor: .systemGray4)
    }

    static var systemGray5: SwiftUI.Color {
        .init(uiColor: .systemGray5)
    }

    static var systemGray6: SwiftUI.Color {
        .init(uiColor: .systemGray6)
    }

    static var lightGray: SwiftUI.Color {
        .init(uiColor: .lightGray)
    }

    static var darkGray: SwiftUI.Color {
        .init(uiColor: .darkGray)
    }

    static var magenta: SwiftUI.Color {
        .init(uiColor: .magenta)
    }
}
