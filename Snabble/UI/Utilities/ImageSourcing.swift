//
//  ImageSourcing.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 10.08.22.
//
//  Copyright © 2022 snabble. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public protocol ImageSourcing {
    /// an option string for an image resource
    var imageSource: String? { get }
}

extension ImageSourcing {
    /// Resolve `imageSource` to `UIImage` or `nil` if nothing is available
    public var uiImage: UIImage? {
        guard let source = imageSource else {
            return nil
        }
        return Asset.image(named: source)
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
    /// Resolve `imageSource` to `Image` or `nil` if nothing is available
    public var image: SwiftUI.Image? {
        guard let source = imageSource else {
            return nil
        }

        return Asset.image(named: source)
    }
}
