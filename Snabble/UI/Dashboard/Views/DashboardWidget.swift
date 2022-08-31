//
//  DashboardWidget.swift
//  
//
//  Created by Uwe Tilemann on 30.08.22.
//

import SwiftUI

/// supported widget types
public enum WidgetType {
    case image
    case text
    case button
    case information
    case previousPurchases
}

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

/// A widget implements the `WidgetProvider` protocol
public protocol WidgetProvider: Codable, Swift.Identifiable {
    /// the widget type
    var type: WidgetType { get }
}

struct WidgetImage: WidgetProvider, ImageSourcing {
    var type: WidgetType {
        .image
    }
    var id: String
    let imageSource: String?
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

struct WidgetText: WidgetProvider, TextStyling {
    var type: WidgetType {
        .text
    }
    var id: String
    let text: String
    let textColorSource: String?
    let textStyleSource: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case textColorSource = "textColor"
        case textStyleSource = "textStyle"
    }
    
    init(id: String, text: String, colorSource: String? = nil, styleSource: String? = nil) {
        self.id = id
        self.text = text
        self.textColorSource = colorSource
        self.textStyleSource = styleSource
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.textColorSource = try container.decodeIfPresent(String.self, forKey: .textColorSource)
        self.textStyleSource = try container.decodeIfPresent(String.self, forKey: .textStyleSource)
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
