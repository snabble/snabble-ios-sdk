//
//  Widget.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation

public protocol Widget: Codable {
    var id: String { get }
    var type: WidgetType { get }
}

public enum WidgetType: String, Codable {
    case text
    case image
    case button
    case information
    case purchases
}

public struct WidgetText: Widget, WidgetTextStyling {
    public let id: String
    public let type: WidgetType = .text
    public let text: String
    public let textColorSource: String
    public let textStyleSource: String

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case textColorSource = "textColor"
        case textStyleSource = "textStyle"
    }
}

public struct WidgetImage: Widget, ImageSourcing {
    public let id: String
    public let type: WidgetType = .image
    public let imageSource: String

    enum CodingKeys: String, CodingKey {
        case id
        case imageSource = "image"
    }
}

public struct WidgetButton: Widget {
    public let id: String
    public let type: WidgetType = .button
    public let text: String
    public let foregroundColorSource: String
    public let backgroundColorSource: String

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case foregroundColorSource = "foregroundColor"
        case backgroundColorSource = "backgroundColor"
    }
}

public struct WidgetInformation: Widget, ImageSourcing {
    public let id: String
    public let type: WidgetType = .information
    public let text: String
    public let imageSource: String?
    public let hideable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case imageSource = "image"
        case hideable
    }
}

public struct WidgetPurchase: Widget {
    public let id: String
    public let type: WidgetType = .purchases
    public let projectId: Identifier<Project>?
}
