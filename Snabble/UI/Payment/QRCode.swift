//
//  QRCode.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

public class QRCode {

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

}
