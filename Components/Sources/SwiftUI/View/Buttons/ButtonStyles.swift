//
//  Utilities.swift
//  PhoneLogin
//
//  Created by Uwe Tilemann on 18.01.23.
//

import SwiftUI
import SnabbleAssetProviding

public struct ProjectPrimaryButtonStyle: ButtonStyle {
    @SwiftUI.Environment(\.projectTrait) private var project
    
    @ScaledMetric private var verticalPadding = 15
    
    public var disabled: Bool
    
    public init(disabled: Bool = false) {
        self.disabled = disabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], verticalPadding)
            .padding([.leading, .trailing], 20)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(Color.projectPrimary())
            )
            .foregroundStyle(Color.onProjectPrimary()
                .opacity(disabled ? 0.5 : 1.0)
            )
            .disabled(disabled)
            .scaleEffect(configuration.isPressed ? 1.05 : 1)
            .animation(.easeOut, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ProjectPrimaryButtonStyle {
    public static var projectPrimary: ProjectPrimaryButtonStyle {
        ProjectPrimaryButtonStyle()
    }
}

public struct ProjectBorderedPrimaryButtonStyle: ButtonStyle {
    @SwiftUI.Environment(\.projectTrait) private var project
    
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 13)
            .padding([.leading, .trailing], 8)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.projectPrimary())
            )
    }
}

extension ButtonStyle where Self == ProjectBorderedPrimaryButtonStyle {
    public static var projectBorderedPrimary: ProjectBorderedPrimaryButtonStyle {
        ProjectBorderedPrimaryButtonStyle()
    }
}

public struct ProjectSecondaryButtonStyle: ButtonStyle {
    @SwiftUI.Environment(\.projectTrait) private var project
    
    public var disabled: Bool
    
    public init(disabled: Bool = false) {
        self.disabled = disabled
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 15)
            .padding([.leading, .trailing], 20)
            .foregroundStyle(Color.projectPrimary())
            .disabled(disabled)
    }
}

extension ButtonStyle where Self == ProjectSecondaryButtonStyle {
    public static var projectSecondary: ProjectSecondaryButtonStyle {
        ProjectSecondaryButtonStyle()
    }
}
