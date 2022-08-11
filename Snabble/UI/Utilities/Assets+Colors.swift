//
//  Assets+Colors.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.08.22.
//

import Foundation
import UIKit

extension Assets {
    enum Color {
        // MARK: - System Colors
        
        static func systemRed(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemRed", domain: domain) ?? .systemRed
        }

        static func systemGreen(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGreen", domain: domain) ?? .systemGreen
        }

        static func systemBlue(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemBlue", domain: domain) ?? .systemBlue
        }

        static func systemOrange(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemOrange", domain: domain) ?? .systemOrange
        }

        static func systemYellow(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemYellow", domain: domain) ?? .systemYellow
        }

        static func systemPink(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemPink", domain: domain) ?? .systemPink
        }

        static func systemPurple(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemPurple", domain: domain) ?? .systemPurple
        }

        static func systemTeal(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemTeal", domain: domain) ?? .systemTeal
        }

        static func systemIndigo(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemIndigo", domain: domain) ?? .systemIndigo
        }

        static func systemBrown(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemBrown", domain: domain) ?? .systemBrown
        }

        @available(iOS 15.0, *)
        static func systemMint(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemMint", domain: domain) ?? .systemMint
        }

        @available(iOS 15.0, *)
        static func systemCyan(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemCyan", domain: domain) ?? .systemCyan
        }

        static func systemGray(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGray", domain: domain) ?? .systemGray
        }

        static func systemGray2(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGray2", domain: domain) ?? .systemGray2
        }

        static func systemGray3(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGray3", domain: domain) ?? .systemGray3
        }

        static func systemGray4(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGray4", domain: domain) ?? .systemGray4
        }

        static func systemGray5(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGray5", domain: domain) ?? .systemGray5
        }

        static func systemGray6(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGray6", domain: domain) ?? .systemGray6
        }

        // MARK: - Other Colors

        @available(iOS 15.0, *)
        static func tintColor(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "tintColor", domain: domain) ?? .tintColor
        }

        static func link(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "link", domain: domain) ?? .link
        }

        static func separator(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "separator", domain: domain) ?? .separator
        }

        static func opaqueSeparator(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "opaqueSeparator", domain: domain) ?? .opaqueSeparator
        }

        // MARK: - Background Colors

        static func systemBackground(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemBackground", domain: domain) ?? .systemBackground
        }

        static func secondarySystemBackground(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "secondarySystemBackground", domain: domain) ?? .secondarySystemBackground
        }

        static func tertiarySystemBackground(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "tertiarySystemBackground", domain: domain) ?? .tertiarySystemBackground
        }

        // MARK: - Grouped Background Colors

        static func systemGroupedBackground(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemGroupedBackground", domain: domain) ?? .systemGroupedBackground
        }

        static func secondarySystemGroupedBackground(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "secondarySystemGroupedBackground", domain: domain) ?? .secondarySystemGroupedBackground
        }

        static func tertiarySystemGroupedBackground(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "tertiarySystemGroupedBackground", domain: domain) ?? .tertiarySystemGroupedBackground
        }

        // MARK: Fill Colors

        static func systemFill(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "systemFill", domain: domain) ?? .systemFill
        }

        static func secondarySystemFill(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "secondarySystemFill", domain: domain) ?? .secondarySystemFill
        }

        static func tertiarySystemFill(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "tertiarySystemFill", domain: domain) ?? .tertiarySystemFill
        }

        static func quaternarySystemFill(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "quaternarySystemFill", domain: domain) ?? .quaternarySystemFill
        }

        // MARK: - Label Colors

        static func label(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "label", domain: domain) ?? .label
        }

        static func secondaryLabel(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "secondaryLabel", domain: domain) ?? .secondaryLabel
        }

        static func tertiaryLabel(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "tertiaryLabel", domain: domain) ?? .tertiaryLabel
        }

        static func quaternaryLabel(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "quaternaryLabel", domain: domain) ?? .quaternaryLabel
        }

        // MARK: - Text Colors

        static func lightText(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "lightText", domain: domain) ?? .lightText
        }

        static func darkText(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "darkText", domain: domain) ?? .darkText
        }

        static func placeholderText(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "placeholderText", domain: domain) ?? .placeholderText
        }

        // MARK: - Default Colors

        static func clear(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "clear", domain: domain) ?? .clear
        }

        static func black(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "black", domain: domain) ?? .black
        }

        static func white(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "white", domain: domain) ?? .white
        }

        // MARK: - Snabble Colors

        static func border(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "border", domain: domain) ?? .systemGray
        }

        static func shadow(in domain: Any? = domain) -> UIColor {
            Assets.color(named: "shadow", domain: domain) ?? .systemGray3
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI
extension Color {

    private static func color(_ uiColor: UIColor) -> SwiftUI.Color {
        if #available(iOS 15.0, *) {
            return Self(uiColor: uiColor)
        } else {
            return Self(uiColor)
        }
    }

    // MARK: - Text Colors
    static func lightText(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.lightText(in: domain))
    }

    static func darkText(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.darkText(in: domain))
    }
    static func placeholderText(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.placeholderText(in: domain))
    }

    // MARK: - Label Colors
    static func label(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.label(in: domain))
    }
    static func secondaryLabel(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.secondaryLabel(in: domain))
    }
    static func tertiaryLabel(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.tertiaryLabel(in: domain))
    }
    static func quaternaryLabel(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.quaternaryLabel(in: domain))
    }

    // MARK: - Background Colors
    static func systemBackground(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemBackground())
    }
    static func secondarySystemBackground(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.secondarySystemBackground())
    }
    static func tertiarySystemBackground(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.tertiarySystemBackground())
    }

    // MARK: - Fill Colors
    static func systemFill(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemFill())
    }
    static func secondarySystemFill(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.secondarySystemFill())
    }
    static func tertiarySystemFill(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.tertiarySystemFill())
    }
    static func quaternarySystemFill(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.quaternarySystemFill())
    }

    // MARK: - Grouped Background Colors
    static func systemGroupedBackground(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGroupedBackground())
    }
    static func secondarySystemGroupedBackground(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.secondarySystemGroupedBackground())
    }
    static func tertiarySystemGroupedBackground(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.tertiarySystemGroupedBackground())
    }

    // MARK: - Gray Colors
    static func systemGray(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGray())
    }
    static func systemGray2(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGray2())
    }
    static func systemGray3(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGray3())
    }
    static func systemGray4(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGray4())
    }
    static func systemGray5(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGray5())
    }
    static func systemGray6(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGray6())
    }

    // MARK: - Other Colors
    static func separator(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.separator())
    }
    static func opaqueSeparator(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.opaqueSeparator())
    }
    static func link(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.link())
    }

    @available(iOS 15.0, *)
    static func tint(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.tintColor())
    }

    // MARK: System Colors
    static func systemBlue(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemBlue())
    }
    static func systemPurple(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemPurple())
    }
    static func systemGreen(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemGreen())
    }
    static func systemYellow(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemYellow())
    }
    static func systemOrange(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemOrange())
    }
    static func systemPink(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemPink())
    }
    static func systemRed(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemRed())
    }
    static func systemTeal(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemTeal())
    }
    static func systemIndigo(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemIndigo())
    }

    @available(iOS 15.0, *)
    static func systemMint(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemMint())
    }

    @available(iOS 15.0, *)
    static func systemCyan(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        color(Assets.Color.systemCyan())
    }
}
#endif
