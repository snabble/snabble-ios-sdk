//
//  DashboardWidget.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation

public protocol DashboardWidget: Codable {
    var id: String { get }
    var type: DashboardWidgetType { get }
}

public enum DashboardWidgetType: String, Codable {
    case text
    case image
    case button
    case information
    case purchases
}

public struct DashboardWidgetText: DashboardWidget, Codable {
    public let id: String
    public let type: DashboardWidgetType = .text
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

public struct DashboardWidgetImage: DashboardWidget, Codable, ImageSourcing {
    public let id: String
    public let type: DashboardWidgetType = .image
    public let imageSource: String?

    enum CodingKeys: String, CodingKey {
        case id
        case imageSource = "image"
    }
}

public struct DashboardWidgetButton: DashboardWidget, Codable {
    public let id: String
    public let type: DashboardWidgetType = .button
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

public struct DashboardWidgetInformation: DashboardWidget, Codable, ImageSourcing {
    public let id: String
    public let type: DashboardWidgetType = .information
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

public struct DashboardWidgetPurchase: DashboardWidget, Codable {
    public let id: String
    public let type: DashboardWidgetType = .purchases
    public let projectId: Identifier<Project>?
}
