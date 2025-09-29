//
//  PDF417.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit
import CoreImage

enum PDF417: CodeRenderer {
    public static func generate(for string: String, scale: Int) -> UIImage? {
        let lightImage = generate(for: string, inScale: scale, for: .light)

        if let darkImage = generate(for: string, inScale: scale, for: .dark) {
            let screenScale = MainActor.assumeIsolated { UIScreen.main.scale }
            let traitCollection = UITraitCollection { mutableTraits in
                MainActor.assumeIsolated {
                    mutableTraits.displayScale = screenScale
                    mutableTraits.userInterfaceStyle = .dark
                }
            }
            lightImage?.imageAsset?.register(darkImage, with: traitCollection)

        }
        return lightImage
    }

    private static func generate(for string: String, inScale scale: Int, for userInterfaceStyle: UIUserInterfaceStyle) -> UIImage? {
        // print("generate pdf417 for \(string)")
        guard
            let data = string.data(using: .isoLatin1, allowLossyConversion: false),
            let filter = CIFilter(name: "CIPDF417BarcodeGenerator")
        else {
            return nil
        }

        // the generated code has 2 pixels of "quiet zone" around it, as the standard mandates.
        // This is fine in light mode, but insufficient in dark mode, so we add some additional space
        let additionalQuietZone = userInterfaceStyle == .dark ? 3 : 0

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(3, forKey: "inputCompactionMode")

        return render(filter.outputImage,
                      scale: scale,
                      additionalQuietZone: additionalQuietZone,
                      orientation: .up)
    }
}
