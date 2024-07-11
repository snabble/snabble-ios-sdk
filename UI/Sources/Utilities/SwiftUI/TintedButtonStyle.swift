//
//  TintedButtonStyle.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI

/// Tinted button style using `Color.accent()` as background color and `Color.onAccent()` as text color
public struct AccentButtonStyle: ButtonStyle {
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 15)
            .padding([.leading, .trailing], 22)
            .background(Color.accent())
            .foregroundColor(Color.onAccent())
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.easeOut, value: configuration.isPressed)
    }
}
