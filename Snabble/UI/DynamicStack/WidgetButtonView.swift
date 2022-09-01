//
//  WidgetButtonView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public protocol WidgetButtonStyling {
    var foregroundColorSource: String { get }
    var backgroundColorSource: String { get }
}

public extension WidgetButtonStyling {
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

public struct WidgetButtonView: View {
    let widget: WidgetButton
    @ObservedObject var viewModel: DynamicStackViewModel
    
    public var body: some View {
        Button(action: {
            viewModel.actionPublisher.send(widget)
        }) {
            Text(widget.text)
                .foregroundColor(widget.foregroundColor)
                .background(widget.backgroundColor)
        }
    }
}
