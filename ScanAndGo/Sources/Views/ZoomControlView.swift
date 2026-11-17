//
//  ZoomControlView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import CameraZoomWheel

struct ZoomControlView: View {
    let model: Shopper

    @State private var zoomLevel: CGFloat = 1
    @State private var zoomSteps: [ZoomStep] = ZoomStep.defaultSteps

    init(model: Shopper) {
        self.model = model
    }

    var body: some View {
        ZoomControl(zoomLevel: $zoomLevel, steps: zoomSteps)
            .task {
                if let zoomFactor = model.barcodeManager.barcodeDetector.zoomFactor {
                    zoomLevel = zoomFactor
                }
                if let steps = model.barcodeManager.barcodeDetector.zoomSteps {
                    zoomSteps = steps
                }
            }
            .onChange(of: model.barcodeManager.barcodeDetector.zoomFactor) { _, newValue in
                guard let newValue, newValue != zoomLevel else { return }
                zoomLevel = newValue
                if let steps = model.barcodeManager.barcodeDetector.zoomSteps {
                    zoomSteps = steps
                }
            }
            .onChange(of: zoomLevel) { _, newValue in
                guard model.barcodeManager.barcodeDetector.zoomFactor != newValue else { return }
                model.barcodeManager.barcodeDetector.zoomFactor = newValue
            }
    }
}
