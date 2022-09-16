//
//  WidgetTextView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

private protocol WidgetTextStyling {
    var textColor: Color { get }
    var textFont: Font { get }
}

private struct NavigationWidget: ViewModifier {
    let text: String
    let active: Bool
    
    func body(content: Content) -> some View {
        if active {
            HStack {
                content
                Spacer()
                SwiftUI.Image(systemName: "chevron.right")
                    .font(Font.subheadline.weight(.medium))
                    .foregroundColor(.gray.opacity(0.666))
            }
            .background(Color.secondarySystemGroupedBackground)
        } else {
            content
        }
    }
}

public struct WidgetTextView: View {
    var widget: WidgetText

    public var body: some View {
        HStack {
            Text(keyed: widget.text)
                .foregroundColor(widget.textColor)
                .font(widget.textFont)
            Spacer()
        }
        .modifier(NavigationWidget(text: Asset.localizedString(forKey: widget.text), active: widget.showDisclosure ?? false))
    }
}

extension WidgetText: WidgetTextStyling {
    var textColor: Color {
        guard
            let source = textColorSource,
            let style = ColorStyle(rawValue: source) else {
            return .primary
        }
        return style.color
    }

    var textFont: Font {
        guard
            let source = textStyleSource,
            let style = TextStyle(rawValue: source) else {
            return .body
        }
        return style.font
    }
}
