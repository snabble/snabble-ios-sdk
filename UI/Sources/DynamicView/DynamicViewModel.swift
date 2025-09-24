//
//  DynamicStackViewModel.swift
//  Snabble-SnabbleSDK
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation
import Combine
import Observation

public struct DynamicAction {
    public let widget: Widget
    public let userInfo: [String: Any]?

    init(widget: Widget, userInfo: [String: Any]? = nil) {
        self.widget = widget
        self.userInfo = userInfo
    }
}

@Observable
public class DynamicViewModel: NSObject, Decodable {
    public var configuration: DynamicViewConfiguration
    public var widgets: [Widget]

    private enum CodingKeys: String, CodingKey {
        case configuration
        case widgets
    }
    
    public init(
        configuration: DynamicViewConfiguration,
        widgets: [Widget]
    ) {
        self.configuration = configuration
        self.widgets = widgets
        super.init()
    }

    private enum WidgetsCodingKeys: String, CodingKey {
        case type
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.configuration = try container.decode(DynamicViewConfiguration.self, forKey: .configuration)

        let wrappers = try container.decode([WidgetWrapper].self, forKey: .widgets)
        self.widgets = wrappers.map { $0.value }
    }

    /// Emits if the widget triigers the action
    /// - `Output` is a `DynamicAction`
    public let actionPublisher = PassthroughSubject<DynamicAction, Never>()
}

struct WidgetWrapper: Decodable {
    let type: WidgetType
    let value: Widget

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(WidgetType.self, forKey: .type)

        switch type {
        case .text:
            value = try WidgetText(from: decoder)
        case .image:
            value = try WidgetImage(from: decoder)
        case .button:
            value = try WidgetButton(from: decoder)
        case .information:
            value = try WidgetInformation(from: decoder)
        case .section:
            value = try WidgetSection(from: decoder)
        case .navigation:
            value = try WidgetNavigation(from: decoder)
        case .toggle:
            value = try WidgetToggle(from: decoder)
        case .locationPermission:
            value = try WidgetLocationPermission(from: decoder)
        case .allStores:
            value = try WidgetAllStores(from: decoder)
        case .startShopping:
            value = try WidgetStartShopping(from: decoder)
        case .connectWifi:
            value = try WidgetConnectWifi(from: decoder)
        case .lastPurchases:
            value = try WidgetLastPurchases(from: decoder)
        case .version:
            value = try WidgetVersion(from: decoder)
        case .customerCard:
            value = try WidgetCustomerCard(from: decoder)
        case .developerMode:
            value = try WidgetDeveloperMode(from: decoder)
        case .multiValue:
            value = try WidgetMultiValue(from: decoder)
        }
    }
}
