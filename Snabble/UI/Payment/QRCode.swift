//
//  QRCode.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation
import CoreImage

public final class QRCode {

    public enum CorrectionLevel: String {
        case L
        case M
        case Q
        case H
    }

    public static func generate(for string: String, scale: Int, _ correctionLevel: CorrectionLevel = .L) -> UIImage? {
        guard
            let data = string.data(using: .isoLatin1, allowLossyConversion: false),
            let filter = CIFilter(name: "CIQRCodeGenerator")
        else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")
        let ciContext = CIContext()
        if let ciImage = filter.outputImage, let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            let size = ciImage.extent.size
            let scale = CGFloat(scale)
            UIGraphicsBeginImageContext(CGSize(width: size.width * scale, height: size.height * scale))
            guard let context = UIGraphicsGetCurrentContext() else {
                return nil
            }
            defer {
                UIGraphicsEndImageContext()
            }
            context.interpolationQuality = .none
            context.draw(cgImage, in: context.boundingBoxOfClipPath)

            if let rawImage = UIGraphicsGetImageFromCurrentImageContext(), let cgImage = rawImage.cgImage {
                return UIImage(cgImage: cgImage, scale: rawImage.scale, orientation: .rightMirrored)
            }
        }

        return nil
    }

    public static func generate(for string: String, size: CGSize, _ correctionLevel: CorrectionLevel = .L) -> UIImage? {
        guard let qrCodeFilter = CIFilter(name: "CIQRCodeGenerator") else { fatalError() }

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
        let transformedImage = qrOutputImage.transformed(by: CGAffineTransform.init(scaleX: scaleX, y: scaleY))

        return UIImage(ciImage: transformedImage)
    }
}
