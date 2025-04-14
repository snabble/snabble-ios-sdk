//
//  AssetProviding.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.08.22.
//

import Foundation
import UIKit
import SwiftUI

public protocol ImageProviding: AnyObject {
    /// Providing an image for the given `name` compatible with the `domain`
    /// - Parameters:
    ///   - name: The name of the image asset or file. For images in asset catalogs, specify the name of the image asset. For PNG images, you may omit the filename extension. For all other file formats, always include the filename extension.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: An object containing the image variant that matches the specified configuration data, or nil if no suitable image was found.
    func image(named name: String, domain: Any?) -> UIImage?

    /// Providing an `SwiftUI` image for the given `name` compatible with the `domain`
    /// - Parameters:
    ///   - name: The name of the image asset or file. For images in asset catalogs, specify the name of the image asset. For PNG images, you may omit the filename extension. For all other file formats, always include the filename extension.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: An object containing the image variant that matches the specified configuration data, or nil if no suitable image was found.
    func image(named name: String, domain: Any?) -> SwiftUI.Image?
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
    ///   - key: The key for a string in the specified table.
    ///   - arguments: `CVargArg` for the key
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: A `String` that matches to the given `key`, or nil if no suitable string was found.
    func localizedString(forKey key: String, arguments: CVarArg..., domain: Any?) -> String?
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
    /// Providing a font for the given `name` and `extension` compatible with the `domain`
    /// - Parameters:
    ///   - name: The name of the font file.
    ///   - ext: The extension of the resource file.
    ///   - domain: The domain, usually the current `Identifier<Project>`
    /// - Returns: The file URL for the resource file or nil if the file could not be located.
    func font(_ name: String, size: CGFloat?, relativeTo textStyle: Font.TextStyle?, domain: Any?) -> SwiftUI.Font?
}

public protocol StyleProviding: AnyObject {
    func shape(domain: Any?) -> (any Shape)?
}

public typealias AssetProviding = ImageProviding & ColorProviding & StringProviding & UrlProviding & FontProviding & StyleProviding
