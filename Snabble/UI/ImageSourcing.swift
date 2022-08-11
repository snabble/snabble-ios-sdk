//
//  ImageSourcing.swift
//  OnboardingUIKit
//
//  Created by Uwe Tilemann on 10.08.22.
//

import Foundation

import UIKit

public protocol ImageSourcing {
    var imageSource: String? { get }
    var imageFromSource: UIImage? { get }
}

extension ImageSourcing {
    public var imageFromSource: UIImage? {
        if let src = imageSource {
            return AssetProvider.shared.image(for: src)
        }
        return nil
    }
}

#if canImport(SwiftUI)
import SwiftUI

extension ImageSourcing {
    public var image: SwiftUI.Image? {
        guard let src = imageSource else {
            return nil
        }
        return SwiftUI.Image(src)
    }
}
#endif
