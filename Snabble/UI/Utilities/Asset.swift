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

    static func color(named name: String, domain: Any? = domain) -> UIColor? {
        provider?.color(named: name, domain: domain) ?? UIColor(named: name, in: BundleToken.bundle, compatibleWith: nil)
    }

    static func preferredFont(forTextStyle style: UIFont.TextStyle, domain: Any? = domain) -> UIFont {
        provider?.preferredFont(forTextStyle: style, weight: nil, domain: domain) ?? .preferredFont(forTextStyle: style)
    }

    static func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight, domain: Any? = domain) -> UIFont {
        provider?.preferredFont(forTextStyle: style, weight: weight, domain: domain) ?? .preferredFont(forTextStyle: style, weight: weight)
    }

    static func image(named name: String, domain: Any? = domain) -> UIImage? {
        provider?.image(named: name, domain: domain) ?? UIImage(named: name, in: BundleToken.bundle, with: nil) ?? UIImage(systemName: name)
    }

    static func localizedString(forKey key: String, table: String? = nil, value: String? = nil, domain: Any? = domain) -> String {
        provider?.localizedString(forKey: key, domain: domain) ?? BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    }

    static func url(forResource name: String?, withExtension ext: String?, domain: Any? = domain) -> URL? {
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
    static func image(named name: String, domain: Any? = domain) -> SwiftUI.Image? {
        guard let uiImage: UIImage = Asset.image(named: name, domain: domain) else {
            return nil
        }
        return SwiftUI.Image(uiImage: uiImage)
    }

    static func color(named name: String, domain: Any? = domain) -> SwiftUI.Color? {
        guard let uiColor: UIColor = Asset.color(named: name, domain: domain) else {
            return nil
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