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
    public static weak var provider: AssetProviding?

    static var domain: Any?

    static func color(named name: String, domain: Any? = domain) -> UIColor? {
        provider?.color(named: name, domain: domain) ?? UIColor(named: name, in: BundleToken.bundle, compatibleWith: nil)
    }

    static func preferredFont(forTextStyle style: UIFont.TextStyle, domain: Any? = domain) -> UIFont {
        provider?.preferredFont(forTextStyle: style, domain: domain) ?? .preferredFont(forTextStyle: style)
    }

    static func image(named name: String, domain: Any? = domain) -> UIImage? {
        provider?.image(named: name, domain: domain) ?? UIImage(named: name, in: BundleToken.bundle, with: nil) ?? UIImage(systemName: name)
    }

    static func localizedString(_ name: String, comment: String, domain: Any? = domain) -> String? {
        provider?.localizedString(name, comment: comment, domain: domain) ?? NSLocalizedString(name, tableName: "SnabbleLocalizable", bundle: BundleToken.bundle, value: name, comment: comment)
    }

    static func url(forResource name: String?, withExtension ext: String?, domain: Any? = domain) -> URL? {
        provider?.url(forResource: name, withExtension: ext, domain: domain) ?? BundleToken.bundle.url(forResource: name, withExtension: ext)
    }
}

extension Assets {
    enum Color {
        static func systemRed(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemRed", domain: domain) ?? .systemRed
        }

        static func systemGreen(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGreen", domain: domain) ?? .systemGreen
        }

        static func systemBlue(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemBlue", domain: domain) ?? .systemBlue
        }

        static func systemOrange(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemOrange", domain: domain) ?? .systemOrange
        }

        static func systemYellow(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemYellow", domain: domain) ?? .systemYellow
        }

        static func systemPink(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemPink", domain: domain) ?? .systemPink
        }

        static func systemPurple(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemPurple", domain: domain) ?? .systemPurple
        }

        static func systemTeal(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemTeal", domain: domain) ?? .systemTeal
        }

        static func systemIndigo(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemIndigo", domain: domain) ?? .systemIndigo
        }

        static func systemBrown(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemBrown", domain: domain) ?? .systemBrown
        }

        @available(iOS 15.0, *)
        static func systemMint(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemMint", domain: domain) ?? .systemMint
        }

        @available(iOS 15.0, *)
        static func systemCyan(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemCyan", domain: domain) ?? .systemCyan
        }

        static func systemGray(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGray", domain: domain) ?? .systemGray
        }

        static func systemGray2(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGray2", domain: domain) ?? .systemGray2
        }

        static func systemGray3(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGray3", domain: domain) ?? .systemGray3
        }

        static func systemGray4(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGray4", domain: domain) ?? .systemGray4
        }

        static func systemGray5(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGray5", domain: domain) ?? .systemGray5
        }

        static func systemGray6(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGray6", domain: domain) ?? .systemGray6
        }

        @available(iOS 15.0, *)
        static func tintColor(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "tintColor", domain: domain) ?? .tintColor
        }

        static func label(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "label", domain: domain) ?? .label
        }

        static func secondaryLabel(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "secondaryLabel", domain: domain) ?? .secondaryLabel
        }

        static func tertiaryLabel(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "tertiaryLabel", domain: domain) ?? .tertiaryLabel
        }

        static func quaternaryLabel(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "quaternaryLabel", domain: domain) ?? .quaternaryLabel
        }

        static func link(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "link", domain: domain) ?? .link
        }

        static func placeholderText(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "placeholderText", domain: domain) ?? .placeholderText
        }

        static func separator(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "separator", domain: domain) ?? .separator
        }

        static func opaqueSeparator(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "opaqueSeparator", domain: domain) ?? .opaqueSeparator
        }

        static func systemBackground(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemBackground", domain: domain) ?? .systemBackground
        }

        static func secondarySystemBackground(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "secondarySystemBackground", domain: domain) ?? .secondarySystemBackground
        }

        static func tertiarySystemBackground(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "tertiarySystemBackground", domain: domain) ?? .tertiarySystemBackground
        }

        static func systemGroupedBackground(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemGroupedBackground", domain: domain) ?? .systemGroupedBackground
        }

        static func secondarySystemGroupedBackground(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "secondarySystemGroupedBackground", domain: domain) ?? .secondarySystemGroupedBackground
        }

        static func tertiarySystemGroupedBackground(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "tertiarySystemGroupedBackground", domain: domain) ?? .tertiarySystemGroupedBackground
        }

        static func systemFill(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "systemFill", domain: domain) ?? .systemFill
        }

        static func secondarySystemFill(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "secondarySystemFill", domain: domain) ?? .secondarySystemFill
        }

        static func tertiarySystemFill(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "tertiarySystemFill", domain: domain) ?? .tertiarySystemFill
        }

        static func quaternarySystemFill(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "quaternarySystemFill", domain: domain) ?? .quaternarySystemFill
        }

        static func lightText(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "lightText", domain: domain) ?? .lightText
        }

        static func darkText(in domain: Any? = domain) -> UIColor? {
            Assets.color(named: "darkText", domain: domain) ?? .darkText
        }
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