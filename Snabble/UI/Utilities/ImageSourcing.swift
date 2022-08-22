//
//  ImageSourcing.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 10.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation

import UIKit

public protocol ImageSourcing {
    /// an option string for an image resource
    var imageSource: String? { get }
    /// returns an optional image resolving `imageSource`
    var imageFromSource: UIImage? { get }
}

extension ImageSourcing {
    /// the implementation resolving `imageSource`
    public var imageFromSource: UIImage? {
        if let src = imageSource {
            return Asset.image(named: src)
        }
        return nil
    }
}

import SwiftUI

extension Text {
    init(key string: String) {
        let value = Asset.localizedString(forKey: string)
        self.init(value)
    }
}

extension SwiftUI.Image {
    // Shop.Finder.Map.pin - pin.fill
    init(named name: String, systemName: String) {
        if let image: UIImage = Asset.image(named: name) {
            self.init(uiImage: image.withRenderingMode(.alwaysTemplate))
        } else {
            self.init(systemName: systemName)
        }
    }
}

extension ImageSourcing {
    /// SwiftUI support
    public var image: SwiftUI.Image? {
        guard let src = imageSource else {
            return nil
        }

        return Asset.image(named: src)
    }
}
