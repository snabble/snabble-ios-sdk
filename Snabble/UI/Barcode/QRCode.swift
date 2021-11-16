//
//  QRCode.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

public enum QRCode {
    // swiftlint:disable identifier_name
    public enum CorrectionLevel: String {
        case L
        case M
        case Q
        case H
    }
    // swiftlint:enable identifier_name

    public static func generate(for string: String, scale: Int, _ correctionLevel: CorrectionLevel = .L) -> UIImage? {
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
        let ciContext = CIContext()
        if let ciImage = filter.outputImage, let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            let scale = CGFloat(scale) * UIScreen.main.scale
            let codeSize = CGSize(width: ciImage.extent.size.width * scale,
                                  height: ciImage.extent.size.height * scale)
            let quietZone = scale * CGFloat(additionalQuietZone)
            UIGraphicsBeginImageContext(
                CGSize(width: codeSize.width + quietZone * 2,
                       height: codeSize.height + quietZone * 2)
            )
            guard let context = UIGraphicsGetCurrentContext() else {
                return nil
            }
            defer {
                UIGraphicsEndImageContext()
            }

            context.interpolationQuality = .none
            UIColor.white.setFill()
            context.fill(context.boundingBoxOfClipPath)
            let drawRect = CGRect(origin: CGPoint(x: quietZone, y: quietZone), size: codeSize)
            context.draw(cgImage, in: drawRect)

            if let rawImage = UIGraphicsGetImageFromCurrentImageContext(), let cgImage = rawImage.cgImage {
                return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .rightMirrored)
            }
        }

        return nil
    }

    public static func generate(for string: String, size: CGSize, _ correctionLevel: CorrectionLevel = .L) -> UIImage? {
        guard let qrCodeFilter = CIFilter(name: "CIQRCodeGenerator") else {
            fatalError()
        }

        guard let data = string.data(using: .isoLatin1, allowLossyConversion: false) else {
            return nil
        }

        qrCodeFilter.setValue(data, forKey: "inputMessage")
        qrCodeFilter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

        guard let qrOutputImage = qrCodeFilter.outputImage else {
            return nil
        }

        let scaleX = size.width / qrOutputImage.extent.size.width
        let scaleY = size.height / qrOutputImage.extent.size.height
        let transformedImage = qrOutputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        return UIImage(ciImage: transformedImage)
    }

    private static var userInterfaceStyle: UIUserInterfaceStyle {
        if #available(iOS 13, *) {
            return UITraitCollection.current.userInterfaceStyle
        }
        return .light
    }
}
