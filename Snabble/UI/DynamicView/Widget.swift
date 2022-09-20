//
//  Widget.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation
import SwiftUI

public protocol Widget: Decodable {
    var id: String { get }
    var type: WidgetType { get }
    var padding: Padding? { get }
}

public enum WidgetType: String, Decodable {
    case text
    case image
    case button
    case information
    case section
    case toggle
    case navigation

    // Snabble Project
    case lastPurchases = "snabble.lastPurchases"
    case customerCard = "snabble.customerCard"

    // Snabble
    case allStores = "snabble.allStores"
    case startShopping = "snabble.startShopping"
    case locationPermission = "snabble.locationPermission"
    case connectWifi = "snabble.connectWifi"
    case version = "snabble.version"
}

public struct WidgetText: Widget {
    public let id: String
    public let type: WidgetType = .text
    public let text: String
    public let textColorSource: String?
    public let textStyleSource: String?
    public let showDisclosure: Bool?
    public let padding: Padding?

    init(
        id: String,
        text: String,
        textColorSource: String? = nil,
        textStyleSource: String? = nil,
        showDisclosure: Bool?,
        padding: Padding? = nil
    ) {
        self.id = id
        self.text = text
        self.textColorSource = textColorSource
        self.textStyleSource = textStyleSource
        self.showDisclosure = showDisclosure
        self.padding = padding
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case textColorSource = "textColor"
        case textStyleSource = "textStyle"
        case showDisclosure
        case padding
    }
}

public struct WidgetImage: Widget, ImageSourcing {
    public let id: String
    public let type: WidgetType = .image
    public let imageSource: String
    public let padding: Padding?

    init(
        id: String,
        imageSource: String,
        padding: Padding? = nil
    ) {
        self.id = id
        self.imageSource = imageSource
        self.padding = padding
    }

    enum CodingKeys: String, CodingKey {
        case id
        case imageSource = "image"
        case padding
    }
}

public struct WidgetButton: Widget {
    public let id: String
    public let type: WidgetType = .button
    public let text: String
    public let foregroundColorSource: String?
    public let backgroundColorSource: String?
    public let padding: Padding?

    public init(
        id: String,
        text: String,
        foregroundColorSource: String? = nil,
        backgroundColorSource: String? = nil,
        padding: Padding? = nil
    ) {
        self.id = id
        self.text = text
        self.foregroundColorSource = foregroundColorSource
        self.backgroundColorSource = backgroundColorSource
        self.padding = padding
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case foregroundColorSource = "foregroundColor"
        case backgroundColorSource = "backgroundColor"
        case padding
    }
}

public struct WidgetInformation: Widget, ImageSourcing {
    public let id: String
    public let type: WidgetType = .information
    public let text: String
    public let imageSource: String?
    public let hideable: Bool
    public let padding: Padding?

    init(
        id: String,
        text: String,
        imageSource: String? = nil,
        hideable: Bool,
        padding: Padding? = nil
    ) {
        self.id = id
        self.text = text
        self.imageSource = imageSource
        self.hideable = hideable
        self.padding = padding
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case imageSource = "image"
        case hideable
        case padding
    }
}

public struct WidgetToggle: Widget {
    public let id: String
    public let type: WidgetType = .toggle
    public let text: String
    public let key: String
    public let padding: Padding?

    init(
        id: String,
        text: String,
        key: String,
        padding: Padding? = nil
    ) {
        self.id = id
        self.text = text
        self.key = key
        self.padding = padding
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case key
        case padding
    }
}

public struct WidgetSection: Widget {
    public let id: String
    public let type: WidgetType = .section
    public let header: String
    public let items: [Widget]
    public let padding: Padding?

    init(
        id: String,
        header: String,
        items: [Widget],
        padding: Padding? = nil
    ) {
        self.id = id
        self.header = header
        self.items = items
        self.padding = padding
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case header
        case items
        case padding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.header = try container.decode(String.self, forKey: .header)

        let wrappers = try container.decode([WidgetWrapper].self, forKey: .items)
        self.items = wrappers.map { $0.value }

        self.padding = try container.decodeIfPresent(Padding.self, forKey: .padding)
    }
}

public struct WidgetNavigation: Widget {
    public let id: String
    public let type: WidgetType = .navigation
    public let text: String
    public let resource: String
    public let padding: Padding?

    init(
        id: String,
        text: String,
        resource: String,
        padding: Padding? = nil
    ) {
        self.id = id
        self.text = text
        self.resource = resource
        self.padding = padding
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case resource
        case padding
    }
}

public struct WidgetVersion: Widget {
    public let id: String
    public let type: WidgetType = .version
    public var padding: Padding?

    enum CodingKeys: String, CodingKey {
        case id
        case padding
    }
    
    public var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "n/a"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "n/a"
        let appVersion = "v\(version) (\(build))"

        let commit = Bundle.main.infoDictionary?["SNGitCommit"] as? String ?? "n/a"
        let sdkVersion = SnabbleSDK.APIVersion.version

        let versionLine2 = BuildConfig.debug ? "SDK v\(sdkVersion)" : commit.prefix(6)
        return "Version\n\(appVersion) \(versionLine2)"
    }
}

public struct WidgetLocationPermission: Widget {
    public let id: String
    public let type: WidgetType = .locationPermission
    public var padding: Padding?

    enum CodingKeys: String, CodingKey {
        case id
        case padding
    }
}

public struct WidgetAllStores: Widget {
    public let id: String
    public let type: WidgetType = .allStores
    public var padding: Padding?

    enum CodingKeys: String, CodingKey {
        case id
        case padding
    }
}

public struct WidgetStartShopping: Widget {
    public let id: String
    public let type: WidgetType = .startShopping
    public var padding: Padding?

    enum CodingKeys: String, CodingKey {
        case id
        case padding
    }
}

public struct WidgetConnectWifi: Widget {
    public let id: String
    public let type: WidgetType = .connectWifi
    public var padding: Padding?

    enum CodingKeys: String, CodingKey {
        case id
        case padding
    }
}

public struct WidgetLastPurchases: Widget {
    public let id: String
    public let type: WidgetType = .lastPurchases
    public let projectId: Identifier<Project>?
    public var padding: Padding?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case padding
    }
}

public struct WidgetCustomerCard: Widget {
    public let id: String
    public let type: WidgetType = .customerCard
    public let projectId: Identifier<Project>?
    public var padding: Padding?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case padding
    }
}
