//
//  Coupon+ImageURL.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

private extension Format {
    var validContentType: Bool {
        return ["image/png", "image/jpg", "image/jpeg", "image/gif", "image/webp"].contains(contentType)
    }
}

extension Coupon {
    /// map image resolution names to what best fits @3x/@2x (assumes @3x for nonisolated contexts)
    nonisolated private static var imageSizes: [String] {
#if os(iOS)
        // Default to @3x resolution order for modern devices when called from nonisolated context
        return ["xxhdpi", "xhdpi", "hdpi", "mdpi", "ldpi", "thumbnail"]
#else
        return ["xhdpi", "hdpi", "mdpi", "ldpi", "thumbnail"]
#endif
    }

    public var imageURL: URL? {
        for size in Self.imageSizes {
            if let img = image?.formats.first(where: { $0.size == size && $0.validContentType }) {
                return img.url
            }
        }
        return nil
    }
}
