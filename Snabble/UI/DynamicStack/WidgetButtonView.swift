//
//  WidgetButtonView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public protocol WidgetButtonStyling {
    var foregroundColor: Color { get }
    var backgroundColor: Color { get }
}

public struct WidgetButtonStyle: ButtonStyle {
    var foregroundColor: Color
    var backgroundColor: Color
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.top, .bottom], 15)
            .padding([.leading, .trailing], 22)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

public struct WidgetButtonView: View {
    let widget: WidgetButton
    @ObservedObject var viewModel: DynamicStackViewModel
    
    public var body: some View {
        HStack {
            Spacer()
            Button(action: {
                viewModel.actionPublisher.send(widget)
            }) {
                Text(keyed: widget.text)
            }
            .buttonStyle(WidgetButtonStyle(foregroundColor: widget.foregroundColor, backgroundColor: widget.backgroundColor))
            Spacer()
        }
        .padding()
    }
}

extension WidgetButton: WidgetButtonStyling {
    public var foregroundColor: Color {
        if let style = ColorStyle(rawValue: foregroundColorSource) {
            return style.color
        }
        return Color.primary
    }
    public var backgroundColor: Color {
        if let style = ColorStyle(rawValue: backgroundColorSource) {
            return style.color
        }
        return Color.systemBackground
    }
}
