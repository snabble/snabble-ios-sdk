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
    nonisolated(unsafe) public static weak var provider: AssetProviding?

    /// Reference to the current domain
    nonisolated(unsafe) public static var domain: Any?

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

    @ViewBuilder
    public static func primaryButtonBackground(domain: Any?) -> some View {
        if let view = provider?.primaryButtonBackground(domain: domain) {
            AnyView(view)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.projectPrimary())
        }
    }

    @ViewBuilder
    public static func primaryBorderedButtonBackground(domain: Any?) -> some View {
        if let view = provider?.primaryBorderedButtonBackground(domain: domain) {
            AnyView(view)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.projectPrimary())
        }
    }

    @ViewBuilder
    public static func secondaryButtonBackground(domain: Any?) -> some View {
        if let view = provider?.secondaryButtonBackground(domain: domain) {
            AnyView(view)
        } else {
            Color.clear
        }
    }
    
    public static func primaryButtonRadius(domain: Any?) -> CGFloat? {
        provider?.primaryButtonRadius(domain: domain) 
    }

    public static func buttonFontWeight(domain: Any?) -> Font.Weight? {
        provider?.buttonFontWeight(domain: domain)
    }

    public static func buttonFont(domain: Any?) -> SwiftUI.Font? {
        provider?.buttonFont(domain: domain)
    }

    public static func primaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? {
        provider?.primaryButtonConfiguration(domain: domain)
    }
    
    public static func secondaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? {
        provider?.secondaryButtonConfiguration(domain: domain)
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

extension CGFloat {
    public static func primaryButtonRadius(domain: Any? = nil) -> CGFloat {
        Asset.primaryButtonRadius(domain: domain ?? Asset.domain) ?? 8
    }
}

extension UIButton {
    public static func primaryButtonConfiguration(domain: Any? = nil) -> UIButton.Configuration? {
        Asset.primaryButtonConfiguration(domain: domain ?? Asset.domain)
    }
    
    public static func secondaryButtonConfiguration(domain: Any? = nil) -> UIButton.Configuration? {
        Asset.secondaryButtonConfiguration(domain: domain ?? Asset.domain)
    }
}
