//
//  AssetProvider.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 08.08.22.
//
import Foundation

#if os(macOS)
public typealias OSImage = NSImage
public typealias OSColor = NSColor
#elseif os(iOS) || os(tvOS) || os(watchOS)
public typealias OSImage = UIImage
public typealias OSColor = UIColor
#endif

public protocol ImageProviding: AnyObject {
    func image(for name: String, domain: Any?) -> OSImage?
}
public protocol ColorProviding: AnyObject {
    func color(for name: String, domain: Any?) -> OSColor?
}
public protocol StringProviding: AnyObject {
    func string(for name: String, domain: Any?) -> String?
}
public protocol UrlProviding: AnyObject {
    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL?
}

public typealias AssetProviding = ImageProviding & ColorProviding & StringProviding & UrlProviding

/**
 `AssetProvider` implementing `AssetProviding`.
*/
public final class AssetProvider: AssetProviding {
    /// A shared instance
    public static var shared = AssetProvider()

    /// A provider to get resources from
    public weak var provider: AssetProviding?

    public func color(for name: String, domain: Any? = nil) -> OSColor? {
        return provider?.color(for: name, domain: domain) ?? OSColor.black
    }

    public func image(for name: String, domain: Any? = nil) -> OSImage? {
        guard let image = provider?.image(for: name, domain: domain) else {
            // default implementation in SDK should:
            // return SwiftGenImageAsset(name: name)
            return nil
        }
        return image
    }

    public func string(for name: String, domain: Any? = nil) -> String? {
        return provider?.string(for: name, domain: domain) ?? name
    }

    public func url(forResource name: String?, withExtension ext: String?, domain: Any? = nil) -> URL? {
        guard let url = provider?.url(forResource: name, withExtension: ext, domain: domain) else {
#if SWIFT_PACKAGE
            return Bundle.module.url(forResource: name, withExtension: ext)
#else
            return Bundle(for: AssetProvider.self).url(forResource: name, withExtension: ext)
#endif
        }
        return url
    }
}
