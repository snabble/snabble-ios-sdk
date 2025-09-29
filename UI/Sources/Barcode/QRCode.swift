//
//  QRCode.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

public enum QRCode: CodeRenderer {
    // swiftlint:disable identifier_name
    public enum CorrectionLevel: String {
        case L
        case M
        case Q
        case H
    }
    // swiftlint:enable identifier_name

    public static func generate(for string: String, scale: Int, _ correctionLevel: CorrectionLevel = .L) -> UIImage? {
        let lightImage = generate(for: string, inScale: scale, withCorrectionLevel: correctionLevel, for: .light)

        if let darkImage = generate(for: string, inScale: scale, withCorrectionLevel: correctionLevel, for: .dark) {
            let traitCollection = UITraitCollection { mutableTraits in
                MainActor.assumeIsolated {
                    mutableTraits.displayScale = UIScreen.main.scale
                    mutableTraits.userInterfaceStyle = .dark
                }
            }
            lightImage?.imageAsset?.register(darkImage, with: traitCollection)

        }
        return lightImage
    }

    private static func generate(for string: String, inScale scale: Int, withCorrectionLevel correctionLevel: CorrectionLevel, for userInterfaceStyle: UIUserInterfaceStyle) -> UIImage? {
        guard
            let data = string.data(using: .isoLatin1, allowLossyConversion: false),
            let filter = CIFilter(name: "CIQRCodeGenerator")
        else {
            return nil
        }

        // the generated code only has 1 pixel of "quiet zone" around it, while the QR code standard
        // mandates 4. This usually doesn't matter in light mode, but does in dark mode, so we add
        // the missing border ourselves
        let additionalQuietZone = userInterfaceStyle == .dark ? 3 : 0

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

        return render(filter.outputImage,
                      scale: scale,
                      additionalQuietZone: additionalQuietZone,
                      orientation: .rightMirrored)
    }
}
