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

    // MARK: - Color
    public static func color(named name: String, domain: Any? = domain) -> UIColor? {
        provider?.color(named: name, domain: domain) ?? UIColor(named: name, in: BundleToken.bundle, compatibleWith: nil)
    }

    public static func color(named name: String, domain: Any? = domain) -> SwiftUI.Color? {
        if let color: SwiftUI.Color = provider?.color(named: name, domain: domain) {
            return color
        }

        if UIColor(named: name, in: BundleToken.bundle, compatibleWith: nil) != nil {
            return SwiftUI.Color(name, bundle: BundleToken.bundle)
        }

        return nil
    }

    // MARK: - Image
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

        if UIImage(systemName: name) != nil {
            return SwiftUI.Image(systemName: name)
        }

        return nil
    }

    // MARK: - Localized String
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

// MARK: - Bundle Token
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

// MARK: SwiftUI - Extensions

extension SwiftUI.Image {
    static func image(named name: String, systemName: String? = nil) -> SwiftUI.Image {
        Asset.image(named: name) ?? SwiftUI.Image(systemName: systemName ?? name)
    }
}

extension Text {
    init(keyed key: String) {
        let value = Asset.localizedString(forKey: key)
        self.init(value)
    }
}
