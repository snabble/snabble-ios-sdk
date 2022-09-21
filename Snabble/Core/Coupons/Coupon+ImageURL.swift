//
//  Coupon+ImageURL.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 11.07.22.
//

import Foundation
import UIKit

private extension Format {
    var validContentType: Bool {
        return ["image/png", "image/jpg", "image/jpeg", "image/gif"].contains(contentType)
    }
}

extension Coupon {
    /// map image resolution names to what best fits @3x/@2x
    private static var imageSizes: [String] {
        var sizes = [ "xhdpi", "hdpi", "mdpi", "ldpi", "thumbnail" ]
        if UIScreen.main.scale >= 3 {
            sizes.insert("xxhdpi", at: 0)
        }
        return sizes
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
