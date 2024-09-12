//
//  ColorStyle.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 01.09.22.
//

import SwiftUI

public enum ColorStyle: String {
    // MARK: - Semantic
    case label
    case secondaryLabel
    case tertiaryLabel
    case quaternaryLabel
    case systemFill
    case secondarySystemFill
    case tertiarySystemFill
    case quaternarySystemFill
    case placeholderText

    @available(iOS 15.0, *)
    case tintColor

    case systemBackground
    case secondarySystemBackground
    case tertiarySystemBackground
    case systemGroupedBackground
    case secondarySystemGroupedBackground
    case tertiarySystemGroupedBackground
    case separator
    case opaqueSeparator
    case link
    case darkText
    case lightText

    @available(*, deprecated, renamed: "systemGroupedBackground")
    case groupTableViewBackground

    // MARK: - Standard
    case systemBlue
    case systemBrown

    @available(iOS 15.0, *)
    case systemCyan

    case systemGreen
    case systemIndigo
    case systemMint
    case systemOrange
    case systemPink
    case systemPurple
    case systemRed
    case systemTeal
    case systemYellow
    case systemGray
    case systemGray2
    case systemGray3
    case systemGray4
    case systemGray5
    case systemGray6

    case clear
    case black
    case blue
    case brown
    case cyan
    case darkGray
    case gray
    case green
    case lightGray
    case magenta
    case orange
    case purple
    case red
    case white
    case yellow
    case pink

    @available(iOS 15.0, *)
    case indigo
    @available(iOS 15.0, *)
    case mint
    @available(iOS 15.0, *)
    case teal

    case accentColor
    case primary
    case secondary

    // MARK: - Snabble
    case projectPrimary
    case onProjectPrimary
    case projectSecondary
    case onProjectSecondary
    case border
    case shadow

    var color: SwiftUI.Color {
        switch self {
        case .label:
            return .label
        case .secondaryLabel:
            return .secondaryLabel
        case .tertiaryLabel:
            return .tertiaryLabel
        case .quaternaryLabel:
            return .quaternaryLabel
        case .systemFill:
            return .systemFill
        case .secondarySystemFill:
            return .secondarySystemFill
        case .tertiarySystemFill:
            return .tertiarySystemFill
        case .quaternarySystemFill:
            return .quaternarySystemFill
        case .placeholderText:
            return .placeholderText
        case .tintColor:
            if #available(iOS 15.0, *) {
                return .tintColor
            }
        case .systemBackground:
            return .systemBackground
        case .secondarySystemBackground:
            return .secondarySystemBackground
        case .tertiarySystemBackground:
            return .tertiarySystemBackground
        case .systemGroupedBackground, .groupTableViewBackground:
            return .systemGroupedBackground
        case .secondarySystemGroupedBackground:
            return .secondarySystemGroupedBackground
        case .tertiarySystemGroupedBackground:
            return .tertiarySystemGroupedBackground
        case .separator:
            return .separator
        case .opaqueSeparator:
            return .opaqueSeparator
        case .link:
            return .link
        case .darkText:
            return .darkText
        case .lightText:
            return .lightText
        case .systemBlue:
            return .systemBlue
        case .systemBrown:
            return .systemBrown
        case .systemCyan:
            if #available(iOS 15.0, *) {
                return .systemCyan
            }
        case .systemGreen:
            return .systemGreen()
        case .systemIndigo:
            return .systemIndigo
        case .systemMint:
            if #available(iOS 15.0, *) {
                return .systemMint
            }
        case .systemOrange:
            return .systemOrange
        case .systemPink:
            return .systemPink
        case .systemPurple:
            return .systemPurple
        case .systemRed:
            return .systemRed()
        case .systemTeal:
            return .systemTeal
        case .systemYellow:
            return .systemYellow
        case .systemGray:
            return .systemGray
        case .systemGray2:
            return .systemGray2
        case .systemGray3:
            return .systemGray3
        case .systemGray4:
            return .systemGray4
        case .systemGray5:
            return .systemGray5
        case .systemGray6:
            return .systemGray6
        case .clear:
            return .clear
        case .black:
            return .black
        case .blue:
            return .blue
        case .brown:
            if #available(iOS 15.0, *) {
                return .brown
            }
        case .cyan:
            if #available(iOS 15.0, *) {
                return .cyan
            }
        case .darkGray:
            return .darkGray
        case .gray:
            return .gray
        case .green:
            return .green
        case .lightGray:
            return .lightGray
        case .magenta:
            return .magenta
        case .orange:
            return .orange
        case .purple:
            return .purple
        case .red:
            return .red
        case .white:
            return .white
        case .yellow:
            return .yellow
        case .pink:
            return .pink
        case .accentColor:
            return .accentColor
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .indigo:
            if #available(iOS 15.0, *) {
                return .indigo
            }
        case .mint:
            if #available(iOS 15.0, *) {
                return .mint
            }
        case .teal:
            if #available(iOS 15.0, *) {
                return .teal
            }
        case .projectPrimary:
            return .projectPrimary()
        case .onProjectPrimary:
            return .onProjectPrimary()
        case .projectSecondary:
            return .projectSecondary()
        case .onProjectSecondary:
            return .onProjectSecondary()
        case .border:
            return .border()
        case .shadow:
            return .shadow()
        }

        return Color.named(rawValue) ?? SwiftUI.Color(rawValue)
    }
}
