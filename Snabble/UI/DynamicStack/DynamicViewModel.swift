//
//  DynamicStackViewModel.swift
//  Snabble-SnabbleSDK
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation
import Combine

public class DynamicViewModel: NSObject, Decodable, ObservableObject {

    public let configuration: DynamicViewConfiguration
    public let widgets: [Widget]

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
    /// - `Output` is the current widget
    public let actionPublisher = PassthroughSubject<Widget, Never>()

    func spacing(for widget: Widget) -> CGFloat? {
        guard let lastItem = widgets.last, lastItem.id != widget.id else {
            return widget.spacing
        }
        return widget.spacing ?? configuration.spacing
    }
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
        case .purchases:
            value = try WidgetPurchase(from: decoder)
        case .section:
            value = try WidgetSection(from: decoder)
        case .toggle:
            value = try WidgetToggle(from: decoder)
        }
    }
}
