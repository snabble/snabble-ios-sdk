//
//  Code128.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 03.11.21.
//

import Foundation
import UIKit
import CoreImage

public enum Code128 {
    public static func generate(for string: String, size: CGSize) -> UIImage? {
        // print("generate code128 for \(string)")
        guard
            let data = string.data(using: .ascii, allowLossyConversion: false),
            let filter = CIFilter(name: "CICode128BarcodeGenerator")
        else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(8, forKey: "inputQuietSpace")

        if let ciImage = filter.outputImage {
            let pixelSize = ciImage.extent.size
            let xScale = size.width / pixelSize.width
            let yScale = size.height / pixelSize.height

            let deviceScale = UIScreen.main.scale
            let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: xScale * deviceScale, y: yScale * deviceScale))

            let image = UIImage(ciImage: scaledImage, scale: deviceScale, orientation: .up)
            return image
        }
        return nil
    }

    public static func generate(for string: String, scale: Int) -> UIImage? {
        // print("generate code128 for \(string)")
        guard
            let data = string.data(using: .ascii, allowLossyConversion: false),
            let filter = CIFilter(name: "CICode128BarcodeGenerator")
        else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(10, forKey: "inputQuietSpace")
        filter.setValue(24, forKey: "inputBarcodeHeight")

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
                return UIImage(cgImage: cgImage, scale: rawImage.scale, orientation: .up)
            }
        }
        return nil
    }
}
