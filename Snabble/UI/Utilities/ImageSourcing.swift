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
    /// Type of the image source
    /// - It has to be `String` or `String?`
    associatedtype ImageSource

    /// describes the image source
    var imageSource: ImageSource { get }
}

extension ImageSourcing {
    /// Resolve `imageSource` to `UIImage` or `nil` if nothing is available
    public var uiImage: UIImage? {
        guard let source = imageSource as? String else {
            return nil
        }
        return UIImage(named: source)
    }
}

extension ImageSourcing {
    /// Resolve `imageSource` to `Image` or `nil` if nothing is available
    public var image: SwiftUI.Image? {
        guard let source = imageSource as? String else {
            return nil
        }

        guard UIImage(named: source) != nil else {
            return nil
        }

        return SwiftUI.Image(source)
    }
}
