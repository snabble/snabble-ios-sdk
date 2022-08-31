//
//  DashboardWidget.swift
//  
//
//  Created by Uwe Tilemann on 30.08.22.
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
        }
    }
}

private struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
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
    }
}

protocol TextStyling {
    var textColorSource: String? { get }
    var textStyleSource: String? { get }
}

extension TextStyling {
    var textStyle: TextStyle {
        if let source = self.textStyleSource, let style = TextStyle(rawValue: source) {
            return style
        }
        return .body
    }
    var colorStyle: ColorStyle {
        if let source = self.textColorSource, let style = ColorStyle(rawValue: source) {
            return style
        }
        return .label
    }
    var color: Color {
        return colorStyle.color
    }
}

struct WidgetTextView: View {
    var widget: WidgetText
    
    var body: some View {
        Text(widget.text)
            .foregroundColor(widget.color)
            .textStyle(widget.textStyle)
    }
}

struct WidgetImageView: View {
    let widget: WidgetImage
    
    var body: some View {
        widget.image
    }
}

struct WidgetImageView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetImageView(widget: WidgetImage(id: "1", imageSource: "emoji-3"))
    }
}
