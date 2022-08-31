//
//  DashboardViewModel.swift
//  Snabble-SnabbleSDK
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation

public class DashboardViewModel: NSObject, Decodable, ObservableObject {

    public let configuration: DashboardConfiguration
    public let widgets: [DashboardWidget]

    enum CodingKeys: String, CodingKey {
        case configuration
        case widgets
    }
    
    public init(
        configuration: DashboardConfiguration,
        widgets: [DashboardWidget]
    ) {
        self.configuration = configuration
        self.widgets = widgets
        super.init()
    }

    enum WidgetsCodingKeys: String, CodingKey {
        case type
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.configuration = try container.decode(DashboardConfiguration.self, forKey: .configuration)

        let wrappers = try container.decode([WidgetWrapper].self, forKey: .widgets)
        self.widgets = wrappers.map { $0.value }
    }
}

private struct WidgetWrapper: Decodable {
    let type: DashboardWidgetType
    let value: DashboardWidget

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(DashboardWidgetType.self, forKey: .type)

        switch type {
        case .text:
            value = try DashboardWidgetText(from: decoder)
        case .image:
            value = try DashboardWidgetImage(from: decoder)
        case .button:
            value = try DashboardWidgetButton(from: decoder)
        case .information:
            value = try DashboardWidgetInformation(from: decoder)
        case .purchases:
            value = try DashboardWidgetPurchase(from: decoder)
        }
    }
}
