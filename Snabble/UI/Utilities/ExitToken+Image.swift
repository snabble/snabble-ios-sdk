//
//  ExitToken+Image.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 05.11.21.
//

import Foundation
import UIKit

public extension ExitToken {
    var image: UIImage? {
        guard let exitCode = value, let format = format else {
            return nil
        }
        switch format {
        case .qr:
            return QRCode.generate(for: exitCode, scale: 4)
        case .code128:
            return Code128.generate(for: exitCode, scale: 2)
        case .unknown, .ean13, .ean8, .itf14, .code39, .dataMatrix, .pdf417:
            print("unsupported exit code format: \(format)")
            return nil
        }
    }
}
