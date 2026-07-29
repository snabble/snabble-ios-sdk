//
//  ShoppingManagerActionView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 23.06.24.
//

import SwiftUI

extension Shopper {
    func detectorImage(for state: InternalBarcodeDetector.State) -> SwiftUI.Image {
        switch state {
        case .idle:
            Image(systemName: "stop.circle.fill")
        case .ready:
            Image(systemName: "bolt.badge.checkmark.fill")
        case .scanning:
            Image(systemName: "record.circle.fill")
        case .pausing:
            Image(systemName: "pause.fill")
        case .batterySaving:
            Image(systemName: "battery.100percent.circle.fill")
        }
    }
}

extension Shopper {
    var actionImage: SwiftUI.Image {
        if processing {
            Image(systemName: "gear.circle.fill")
        } else {
            Image(systemName: scanningPaused ? "eye.slash.fill" : "eye.fill")
        }
    }
}
