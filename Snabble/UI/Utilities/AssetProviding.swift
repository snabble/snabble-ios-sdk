//
//  AssetProviding.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.08.22.
//

import Foundation
import UIKit

public protocol ImageProviding: AnyObject {
    /// Providing an image for the given `name` compatible with the `domain`
    /// - Parameters:
    ///   - name: The name of the image asset or file. For images in asset catalogs, specify the name of the image asset. For PNG images, you may omit the filename extension. For all other file formats, always include the filename extension.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: An object containing the image variant that matches the specified configuration data, or nil if no suitable image was found.
    func image(named name: String, domain: Any?) -> UIImage?
}

public protocol ColorProviding: AnyObject {
    /// Providing a color for the given `name` compatible with the `domain`
    /// - Parameters:
    ///   - name: The name of the asset containing the color.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: An initialized color object. The returned object uses the color space specified for the asset.
    func color(named name: String, domain: Any?) -> UIColor?
}

public protocol StringProviding: AnyObject {
    /// Providing a localizedString for the given `name` compatible with the `domain`
    ///
    /// Make sure not to the return `key`
    /// - Parameters:
    ///   - name: The key for a string in the specified table.
    ///   - comment: The comment to place above the key-value pair in the strings file. This parameter provides the translator with some context about the localized string’s presentation to the user.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: A `String` that matches to the given `key`, or nil if no suitable string was found.
    func localizedString(_ key: String, comment: String, domain: Any?) -> String?
}

public protocol UrlProviding: AnyObject {
    /// Providing an url for the given `name` and `extension` compatible with the `domain`
    /// - Parameters:
    ///   - name: The name of the resource file.
    ///   - ext: The extension of the resource file.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: The file URL for the resource file or nil if the file could not be located.
    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL?
}

public protocol FontProviding: AnyObject {
    /// Providing a font for the given `style` compatible with the `domain`
    /// - Parameters:
    ///   - style: The text style for which to return a font. See UIFont.TextStyle for recognized values.
    ///   - weight: The text weight for which to return a font. See UIFont.Weight for reconized values.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: The font associated with the specified text style.
    func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight?, domain: Any?) -> UIFont?
}

public protocol AppearanceProviding: AnyObject {
    /// Providing a `CustomAppearance` for the given `projectId`
    /// - Parameter domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: The custom appearance for the specified projectId or `nil`
    func appearance(for domain: Any?) -> CustomAppearance?
}

public typealias AssetProviding = ImageProviding & ColorProviding & StringProviding & UrlProviding & FontProviding & AppearanceProviding
