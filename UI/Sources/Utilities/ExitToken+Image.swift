//
//  ExitToken+Image.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 23.11.21.
//

import Foundation
import UIKit
import SnabbleCore

public extension ExitToken {
    var image: UIImage? {
        guard let format = format, let value = value else {
            return nil
        }
        switch format {
        case .qr:
            return QRCode.generate(for: value, scale: 6)
        case .code128:
            return Code128.generate(for: value, scale: 2)
        case .unknown, .ean13, .ean8, .itf14, .code39, .dataMatrix, .pdf417:
            print("unsupported exit code format: \(format)")
            return nil
        }
    }
}
