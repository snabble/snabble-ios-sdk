//
//  Widget.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 31.08.22.
//

import Foundation

public protocol Widget: Decodable {
    var id: String { get }
    var type: WidgetType { get }
    
    /// Additional Bottom Spacing
    var spacing: CGFloat? { get }
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
    public let spacing: CGFloat?

    init(
        id: String,
        text: String,
        textColorSource: String? = nil,
        textStyleSource: String? = nil,
        showDisclosure: Bool?,
        spacing: CGFloat? = nil
    ) {
        self.id = id
        self.text = text
        self.textColorSource = textColorSource
        self.textStyleSource = textStyleSource
        self.spacing = spacing
        self.showDisclosure = showDisclosure
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case textColorSource = "textColor"
        case textStyleSource = "textStyle"
        case spacing
        case showDisclosure
    }
}

public struct WidgetImage: Widget, ImageSourcing {
    public let id: String
    public let type: WidgetType = .image
    public let imageSource: String
    public let spacing: CGFloat?

    init(
        id: String,
        imageSource: String,
        spacing: CGFloat? = nil
    ) {
        self.id = id
        self.imageSource = imageSource
        self.spacing = spacing
    }

    enum CodingKeys: String, CodingKey {
        case id
        case imageSource = "image"
        case spacing
    }
}

public struct WidgetButton: Widget {
    public let id: String
    public let type: WidgetType = .button
    public let text: String
    public let foregroundColorSource: String?
    public let backgroundColorSource: String?
    public let spacing: CGFloat?

    public init(
        id: String,
        text: String,
        foregroundColorSource: String? = nil,
        backgroundColorSource: String? = nil,
        spacing: CGFloat? = nil
    ) {
        self.id = id
        self.text = text
        self.foregroundColorSource = foregroundColorSource
        self.backgroundColorSource = backgroundColorSource
        self.spacing = spacing
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case foregroundColorSource = "foregroundColor"
        case backgroundColorSource = "backgroundColor"
        case spacing
    }
}

public struct WidgetInformation: Widget, ImageSourcing {
    public let id: String
    public let type: WidgetType = .information
    public let text: String
    public let imageSource: String?
    public let hideable: Bool
    public let spacing: CGFloat?

    init(
        id: String,
        text: String,
        imageSource: String? = nil,
        hideable: Bool,
        spacing: CGFloat? = nil
    ) {
        self.id = id
        self.text = text
        self.imageSource = imageSource
        self.hideable = hideable
        self.spacing = spacing
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case imageSource = "image"
        case hideable
        case spacing
    }
}

public struct WidgetToggle: Widget {
    public let id: String
    public let type: WidgetType = .toggle
    public let text: String
    public let key: String
    public let spacing: CGFloat?

    init(
        id: String,
        text: String,
        key: String,
        spacing: CGFloat? = nil
    ) {
        self.id = id
        self.text = text
        self.key = key
        self.spacing = spacing
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case key
        case spacing
    }
}

public struct WidgetSection: Widget {
    public let id: String
    public let type: WidgetType = .section
    public let header: String
    public let items: [Widget]
    public let spacing: CGFloat?

    init(
        id: String,
        header: String,
        items: [Widget],
        spacing: CGFloat? = nil
    ) {
        self.id = id
        self.header = header
        self.items = items
        self.spacing = spacing
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case header
        case items
        case spacing
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.header = try container.decode(String.self, forKey: .header)

        let wrappers = try container.decode([WidgetWrapper].self, forKey: .items)
        self.items = wrappers.map { $0.value }

        self.spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
    }
}

public struct WidgetNavigation: Widget {
    public let id: String
    public let type: WidgetType = .navigation
    public let text: String
    public let resource: String
    public let spacing: CGFloat?

    init(
        id: String,
        text: String,
        resource: String,
        spacing: CGFloat? = nil
    ) {
        self.id = id
        self.text = text
        self.resource = resource
        self.spacing = spacing
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case resource
        case spacing
    }
}

public struct WidgetVersion: Widget {
    public let id: String
    public let type: WidgetType = .version
    public var spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case id
        case spacing
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
    public var spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case id
        case spacing
    }
}

public struct WidgetAllStores: Widget {
    public let id: String
    public let type: WidgetType = .allStores
    public var spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case id
        case spacing
    }
}

public struct WidgetStartShopping: Widget {
    public let id: String
    public let type: WidgetType = .startShopping
    public var spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case id
        case spacing
    }
}

public struct WidgetConnectWifi: Widget {
    public let id: String
    public let type: WidgetType = .connectWifi
    public var spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case id
        case spacing
    }
}

public struct WidgetLastPurchases: Widget {
    public let id: String
    public let type: WidgetType = .lastPurchases
    public let projectId: Identifier<Project>?
    public var spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case spacing
    }
}

public struct WidgetCustomerCard: Widget {
    public let id: String
    public let type: WidgetType = .customerCard
    public let projectId: Identifier<Project>?
    public var spacing: CGFloat?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId
        case spacing
    }
}
