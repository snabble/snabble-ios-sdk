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
    public static var domain: Any?

    // MARK: - Color
    public static func color(named name: String, domain: Any? = domain) -> UIColor? {
        provider?.color(named: name, domain: domain) ?? UIColor(named: name, in: Bundle.module, compatibleWith: nil)
    }

    // MARK: - Image
    public static func image(named name: String, domain: Any? = domain) -> UIImage? {
        provider?.image(named: name, domain: domain) ?? UIImage(named: name, in: Bundle.module, with: nil) ?? UIImage(systemName: name)
    }

    public static func image(named name: String, domain: Any? = domain, bundle: Bundle? = nil) -> SwiftUI.Image? {
        if let image: SwiftUI.Image = provider?.image(named: name, domain: domain) {
            return image
        }
        
        if UIImage(named: name, in: Bundle.module, with: nil) != nil {
            return SwiftUI.Image(name, bundle: Bundle.module)
        }

        return nil
    }

    // MARK: - Localized String
    public static func localizedString(forKey key: String, arguments: CVarArg..., table: String? = nil, value: String? = nil, domain: Any? = domain, bundle: Bundle? = nil) -> String {
        guard let localizedString = provider?.localizedString(forKey: key, arguments: arguments, domain: domain) else {
            let format = Bundle.module.localizedString(forKey: key, value: value, table: table)
            return String.localizedStringWithFormat(format, arguments)
        }
        return localizedString
    }

    public static func url(forResource name: String?, withExtension ext: String?, domain: Any? = domain, bundle: Bundle? = nil) -> URL? {
        provider?.url(forResource: name, withExtension: ext, domain: domain) ?? Bundle.module.url(forResource: name, withExtension: ext)
    }
    public static func font(_ name: String, size: CGFloat?, relativeTo textStyle: Font.TextStyle?, domain: Any?) -> SwiftUI.Font? {
        provider?.font(name, size: size, relativeTo: textStyle, domain: domain) ?? nil
    }
    public static func shape(domain: Any?) -> (any SwiftUI.Shape)? {
        provider?.shape(domain: domain) ?? nil
    }
}

// MARK: SwiftUI - Extensions

extension SwiftUI.Image {
    public static func image(named name: String, systemName: String? = nil, domain: Any? = nil) -> SwiftUI.Image {
        Asset.image(named: name, domain: domain ?? Asset.domain) ?? SwiftUI.Image(systemName: systemName ?? name)
    }
}

extension Text {
    public init(keyed key: String) {
        let value = Asset.localizedString(forKey: key)
        self.init(value)
    }
}
