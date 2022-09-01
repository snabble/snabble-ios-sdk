//
//  WidgetTextView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

private protocol WidgetTextStyling {
    var textColorSource: String { get }
    var textStyleSource: String { get }
}

private extension WidgetTextStyling {
    var textStyle: TextStyle {
        if let style = TextStyle(rawValue: self.textStyleSource) {
            return style
        }
        return .body
    }
    var colorStyle: ColorStyle {
        if let style = ColorStyle(rawValue: self.textColorSource) {
            return style
        }
        return .label
    }

    var color: Color {
        return colorStyle.color
    }

    var font: Font {
        textStyle.font
    }
}

public struct WidgetTextView: View {
    var widget: WidgetText
    
    public var body: some View {
        Text(keyed: widget.text)
            .foregroundColor(widget.color)
            .font(widget.font)
    }
}

extension WidgetText: WidgetTextStyling {}
