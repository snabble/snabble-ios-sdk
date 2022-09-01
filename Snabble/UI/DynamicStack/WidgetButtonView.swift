//
//  WidgetButtonView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

private protocol WidgetButtonStyling {
    var foregroundColorSource: String { get }
    var backgroundColorSource: String { get }
}

private extension WidgetButtonStyling {
    var foregroundColor: Color {
        if let style = ColorStyle(rawValue: self.foregroundColorSource) {
            return style.color
        }
        return Color.primary
    }
    var backgroundColor: Color {
        if let style = ColorStyle(rawValue: self.backgroundColorSource) {
            return style.color
        }
        return Color.systemBackground
    }
}

private struct WidgetButtonStyle: ButtonStyle {
    var foregroundColor: Color
    var backgroundColor: Color
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}

public struct WidgetButtonView: View {
    let widget: WidgetButton
    @ObservedObject var viewModel: DynamicStackViewModel
    
    public var body: some View {
        HStack {
            Button(action: {
                viewModel.actionPublisher.send(widget)
            }) {
                Text(keyed: widget.text)
            }
            .buttonStyle(
                WidgetButtonStyle(
                    foregroundColor: widget.foregroundColor,
                    backgroundColor: widget.backgroundColor
                )
            )
        }
    }
}

extension WidgetButton: WidgetButtonStyling {}
