//
//  CodeRenderer.swift
//  Snabble
//
//  Created by Gereon Steffens on 01.02.22.
//

import UIKit
import CoreImage

protocol CodeRenderer { }

extension CodeRenderer {
    static func render(_ image: CIImage?,
                       scale: Int,
                       additionalQuietZone: Int,
                       orientation: UIImage.Orientation) -> UIImage? {
        let ciContext = CIContext()
        guard
            let ciImage = image,
            let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        else {
            return nil
        }

        let scale = CGFloat(scale) * MainActor.assumeIsolated { UIScreen.main.scale }
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
            return UIImage(cgImage: cgImage, scale: MainActor.assumeIsolated { UIScreen.main.scale }, orientation: orientation)
        }

        return nil
    }
}
