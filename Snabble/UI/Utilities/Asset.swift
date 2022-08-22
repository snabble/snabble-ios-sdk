//
//  Asset.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.08.22.
//

import Foundation
import UIKit
import SwiftUI

public enum Asset {
    /// Reference to the implementation of the `AssetProviding` implementation
    public static weak var provider: AssetProviding?

    /// Reference to the current domain
    public internal(set) static var domain: Any?

    public static func color(named name: String, domain: Any? = domain) -> UIColor? {
        provider?.color(named: name, domain: domain) ?? UIColor(named: name, in: BundleToken.bundle, compatibleWith: nil)
    }

    public static func preferredFont(forTextStyle style: UIFont.TextStyle, domain: Any? = domain) -> UIFont {
        provider?.preferredFont(forTextStyle: style, weight: nil, domain: domain) ?? .preferredFont(forTextStyle: style)
    }

    public static func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight, domain: Any? = domain) -> UIFont {
        provider?.preferredFont(forTextStyle: style, weight: weight, domain: domain) ?? .preferredFont(forTextStyle: style, weight: weight)
    }

    public static func image(named name: String, domain: Any? = domain) -> UIImage? {
        provider?.image(named: name, domain: domain) ?? UIImage(named: name, in: BundleToken.bundle, with: nil) ?? UIImage(systemName: name)
    }

    public static func image(named name: String, domain: Any? = domain) -> SwiftUI.Image? {
        if let image: SwiftUI.Image = provider?.image(named: name, domain: domain) {
            return image
        }
        if UIImage(named: name, in: BundleToken.bundle, with: nil) != nil {
            return SwiftUI.Image(name, bundle: BundleToken.bundle)
        }
        return SwiftUI.Image(systemName: name)
    }

    public static func localizedString(forKey key: String, arguments: CVarArg..., table: String? = nil, value: String? = nil, domain: Any? = domain) -> String {
        guard let localizedString = provider?.localizedString(forKey: key, arguments: arguments, domain: domain) else {
            let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
            return String.localizedStringWithFormat(format, arguments)
        }
        return localizedString
    }

    public static func url(forResource name: String?, withExtension ext: String?, domain: Any? = domain) -> URL? {
        provider?.url(forResource: name, withExtension: ext, domain: domain) ?? BundleToken.bundle.url(forResource: name, withExtension: ext)
    }
}

// swiftlint:disable:next convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
#if SWIFT_PACKAGE
      return Bundle.module
#else
      return SnabbleSDKBundle.main
#endif
  }()
}

extension Asset {
    static func color(named name: String, domain: Any? = domain) -> SwiftUI.Color? {
        guard let uiColor: UIColor = Asset.color(named: name, domain: domain) else {
            return SwiftUI.Color(name)
        }
        if #available(iOS 15.0, *) {
            return SwiftUI.Color(uiColor: uiColor)
        } else {
            return SwiftUI.Color(uiColor)
        }
    }

    static func preferredFont(forTextStyle style: UIFont.TextStyle, domain: Any? = domain) -> Font {
        let uiFont: UIFont = Asset.preferredFont(forTextStyle: style, domain: domain)
        return SwiftUI.Font.custom(uiFont.familyName, size: uiFont.pointSize, relativeTo: style.textStyle)
    }
}

private extension UIFont.TextStyle {
    var textStyle: Font.TextStyle {
        switch self {
        case .body:
            return .body
        case .callout:
            return .callout
        case .caption1:
            return .caption
        case .caption2:
            return .caption2
        case .footnote:
            return .footnote
        case .headline:
            return .headline
        case .largeTitle:
            return .largeTitle
        case .subheadline:
            return .subheadline
        case .title1:
            return .title
        case .title2:
            return .title2
        case .title3:
            return .title3
        default:
            return .body
        }
    }
}
