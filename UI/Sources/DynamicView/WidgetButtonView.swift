//
//  WidgetButtonView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI
import SnabbleAssetProviding
import SnabbleComponents

private protocol WidgetButtonStyling {
    var foregroundColor: Color { get }
    var backgroundColor: Color? { get }
}

public struct WidgetButtonView: View {
    @SwiftUI.Environment(\.projectTrait) private var project
    
    let widget: WidgetButton
    let action: (WidgetButton) -> Void
    
    public var body: some View {
        HStack {
            Button(action: {
                action(widget)
            }) {
                Text(keyed: widget.text)
                    .foregroundColor(widget.foregroundColor)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(widget.backgroundColor)
                    .cornerRadius(8)
            }
        }
    }
}

extension WidgetButton: WidgetButtonStyling {
    
    var foregroundColor: Color {
        guard
            let source = foregroundColorSource,
            let style = ColorStyle(rawValue: source) else {
            return Color.projectPrimary()
        }
        return style.color

    }
    var backgroundColor: Color? {
        guard
            let source = backgroundColorSource,
            let style = ColorStyle(rawValue: source) else {
            return nil
        }
        return style.color
    }
}
