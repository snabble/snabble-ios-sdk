//
//  ColorStyle.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 01.09.22.
//

import SwiftUI

public enum ColorStyle: String {
    case label
    case secondaryLabel
    case accent
    case onAccent
    case border
    case shadow
    case clear

    var color: SwiftUI.Color {
        switch self {
        case .label:
            return Color.label
        case .secondaryLabel:
            return Color.secondaryLabel
        case .accent:
            return Color.accent()
        case .onAccent:
            return Color.onAccent()
        case .border:
            return Color.border()
        case .shadow:
            return Color.shadow()
        case .clear:
            return Color.clear
        default:
            break
        }
        return Color(self.rawValue)
    }
}
