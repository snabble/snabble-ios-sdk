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

public struct WidgetTextView: View {
    var widget: WidgetText
    
    public var body: some View {
        HStack {
            Text(keyed: widget.text)
                .foregroundColor(widget.textColor)
                .font(widget.textFont)
            Spacer()
        }
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
