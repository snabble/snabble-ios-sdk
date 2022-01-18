//
//  PDF417.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit
import CoreImage

enum PDF417 {
    public static func generate(for string: String, scale: Int) -> UIImage? {
        // print("generate pdf417 for \(string)")
        guard
            let data = string.data(using: .isoLatin1, allowLossyConversion: false),
            let filter = CIFilter(name: "CIPDF417BarcodeGenerator")
        else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(3, forKey: "inputCompactionMode")

        let ciContext = CIContext()
        if let ciImage = filter.outputImage, let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            let size = ciImage.extent.size
            let scale = CGFloat(scale)
            UIGraphicsBeginImageContext(CGSize(width: size.width * scale, height: size.height * scale))
            guard let context = UIGraphicsGetCurrentContext() else {
                return nil
            }

            context.interpolationQuality = .none
            context.draw(cgImage, in: context.boundingBoxOfClipPath)

            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
}
