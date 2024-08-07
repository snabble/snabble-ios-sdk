//
//  Utilities.swift
//  PhoneLogin
//
//  Created by Uwe Tilemann on 18.01.23.
//

import SwiftUI

public struct AccentButtonStyle: ButtonStyle {
    var disabled: Bool
    
    public init(disabled: Bool = false) {
        self.disabled = disabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 15)
            .padding([.leading, .trailing], 20)
            .background(Color.accent())
            .foregroundColor(.white.opacity(disabled ? 0.5 : 1.0))
            .disabled(disabled)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

public struct BorderedButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 13)
            .padding([.leading, .trailing], 8)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(.accentColor)
            )
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    var disabled: Bool
    
    public init(disabled: Bool = false) {
        self.disabled = disabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 15)
            .padding([.leading, .trailing], 20)
            .foregroundColor(.accent())
            .disabled(disabled)
    }
}
