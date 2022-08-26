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

    public static func accent(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "accent", domain: domain) ?? UIColor(red: 0, green: 119.0 / 255.0, blue: 187.0 / 255.0, alpha: 1)
    }

    public static func onAccent(in domain: Any? = Asset.domain) -> UIColor {
        Asset.color(named: "onAccent", domain: domain) ?? accent(in: domain).contrast ?? .label
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

    public static func accent(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.accent(in: domain))
    }

    public static func onAccent(in domain: Any? = Asset.domain) -> SwiftUI.Color {
        color(UIColor.onAccent(in: domain))
    }
}
