//
//  Code128.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 03.11.21.
//

import Foundation
import UIKit
import CoreImage

public enum Code128: CodeRenderer {
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

        return render(filter.outputImage, scale: scale, additionalQuietZone: 0, orientation: .up)
    }
}
