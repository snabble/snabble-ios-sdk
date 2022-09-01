//
//  WidgetTextView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 01.09.22.
//

import SwiftUI

public enum ColorStyle: String {
    case label
    case secondaryLabel
    case accent
    case onAccent
    case border
    case shadow
    
    var color: SwiftUI.Color {
        switch self {
        case .label:
            return Color.label
        case .secondaryLabel:
            return Color.secondaryLabel
        case .accent:
            return Color.accent()
        case .onAccent:
            return Color.onAccent()
        case .border:
            return Color.border()
        case .shadow:
            return Color.shadow()
            
        default:
            break
        }
        print("getting color for \(self.rawValue)")
        return Color(self.rawValue)
    }
}

public enum TextStyle: String {
    case body
    case footnote
    case headline
    case title
}

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        switch style {
        case .body:
            return AnyView(modifier(BodyStyle()))
        case .footnote:
            return AnyView(modifier(FootnoteStyle()))
        case .headline:
            return AnyView(modifier(HeadlineStyle()))
        case .title:
            return AnyView(modifier(TitleStyle()))
        }
    }
}

private struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .padding(.bottom, 8)
    }
}
private struct FootnoteStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.footnote)
    }
}
private struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding(.bottom, 8)
    }
}
private struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .padding([.top, .bottom], 12)
    }
}

public protocol WidgetTextStyling {
    var textColorSource: String { get }
    var textStyleSource: String { get }
}

public extension WidgetTextStyling {
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
}

public struct WidgetTextView: View {
    var widget: WidgetText
    
    public var body: some View {
        Text(keyed: widget.text)
            .foregroundColor(widget.color)
            .textStyle(widget.textStyle)
    }
}
