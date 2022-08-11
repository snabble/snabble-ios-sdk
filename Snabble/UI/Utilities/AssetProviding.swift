//
//  AssetProviding.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.08.22.
//

import Foundation
import UIKit

public protocol ImageProviding: AnyObject {
    func image(named name: String, domain: Any?) -> UIImage?
}
public protocol ColorProviding: AnyObject {
    func color(named name: String, domain: Any?) -> UIColor?
}
public protocol StringProviding: AnyObject {
    func localizedString(_ name: String, comment: String, domain: Any?) -> String?
}
public protocol UrlProviding: AnyObject {
    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL?
}
public protocol FontProviding: AnyObject {
    func preferredFont(forTextStyle style: UIFont.TextStyle, domain: Any?) -> UIFont
}

public typealias AssetProviding = ImageProviding & ColorProviding & StringProviding & UrlProviding & FontProviding

public enum Assets {
    public static var provider: AssetProviding?

    static func color(named name: String, domain: Any? = nil) -> UIColor? {
        provider?.color(named: name, domain: domain) ?? UIColor(named: name, in: BundleToken.bundle, compatibleWith: nil)
    }

    static func preferredFont(forTextStyle style: UIFont.TextStyle, domain: Any? = nil) -> UIFont {
        provider?.preferredFont(forTextStyle: style, domain: domain) ?? .preferredFont(forTextStyle: style)
    }

    static func image(named name: String, domain: Any? = nil) -> UIImage? {
        provider?.image(named: name, domain: domain) ?? UIImage(named: name, in: BundleToken.bundle, with: nil) ?? UIImage(systemName: name)
    }

    static func localizedString(_ name: String, comment: String, domain: Any? = nil) -> String? {
        provider?.localizedString(name, comment: comment, domain: domain) ?? NSLocalizedString(name, tableName: "SnabbleLocalizable", bundle: BundleToken.bundle, value: name, comment: comment)
    }

    static func url(forResource name: String?, withExtension ext: String?, domain: Any? = nil) -> URL? {
        provider?.url(forResource: name, withExtension: ext, domain: domain) ?? BundleToken.bundle.url(forResource: name, withExtension: ext)
    }
}

// swiftlint:disable:next convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}

#if canImport(SwiftUI)
import SwiftUI

extension Assets {
    static func image(named name: String, domain: Any?) -> SwiftUI.Image? {
        guard let uiImage: UIImage = Assets.image(named: name, domain: domain) else {
            return nil
        }
        return SwiftUI.Image(uiImage: uiImage)
    }

    static func color(named name: String, domain: Any?) -> SwiftUI.Color? {
        guard let uiColor: UIColor = Assets.color(named: name, domain: domain) else {
            return nil
        }
        if #available(iOS 15.0, *) {
            return SwiftUI.Color(uiColor: uiColor)
        } else {
            return SwiftUI.Color(uiColor)
        }
    }

    static func preferredFont(forTextStyle style: UIFont.TextStyle, domain: Any?) -> Font {
        let uiFont: UIFont = Assets.preferredFont(forTextStyle: style, domain: domain)
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
#endif
