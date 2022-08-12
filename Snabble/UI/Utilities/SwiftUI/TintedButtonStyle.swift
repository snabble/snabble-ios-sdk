//
//  TintedButtonStyle.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI

extension Color {
    static func accent(in domain: Any? = Assets.domain) -> SwiftUI.Color {
        return Color.systemBackground()
    }
}

/// Tinted button style using `Color.accent()` as background color and `Color.label()` as text color
public struct AccentButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(15)
            .background(Color.accent())
            .foregroundColor(Color.label())
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
