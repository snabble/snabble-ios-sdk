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
            .fontWeight(Font.buttonWeight())
            .padding([.top, .bottom], verticalPadding)
            .padding([.leading, .trailing], 20)
            .background(Asset.primaryButtonBackground(domain: nil))
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
    
    public static func projectPrimary(disabled: Bool) -> ProjectPrimaryButtonStyle {
        ProjectPrimaryButtonStyle(disabled: disabled)
    }
}

public struct ProjectBorderedPrimaryButtonStyle: ButtonStyle {
    @SwiftUI.Environment(\.projectTrait) private var project
    
    public init() { }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(Font.buttonWeight())
            .padding([.top, .bottom], 13)
            .padding([.leading, .trailing], 8)
            .background(Asset.primaryBorderedButtonBackground(domain: nil))
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
            .fontWeight(Font.buttonWeight())
            .padding([.top, .bottom], 15)
            .padding([.leading, .trailing], 20)
            .background(Asset.secondaryButtonBackground(domain: nil))
            .foregroundStyle(Color.projectPrimary())
            .disabled(disabled)
    }
}

extension ButtonStyle where Self == ProjectSecondaryButtonStyle {
    public static var projectSecondary: ProjectSecondaryButtonStyle {
        ProjectSecondaryButtonStyle()
    }
    
    public static func projectSecondary(disabled: Bool) -> ProjectSecondaryButtonStyle {
        ProjectSecondaryButtonStyle(disabled: disabled)
    }
}
