//
//  TintedButtonStyle.swift
//  Snabble
//
//  Created by Uwe Tilemann on 12.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import SwiftUI
import SnabbleAssetProviding
import SnabbleComponents

/// Tinted button style using `Color.projectPrimary()` as background color and `Color.onProjectPrimary()` as text color
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.projectTrait) private var project
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 15)
            .padding([.leading, .trailing], 22)
            .background(Color.projectPrimary())
            .foregroundColor(Color.onProjectPrimary())
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.easeOut, value: configuration.isPressed)
    }
}
