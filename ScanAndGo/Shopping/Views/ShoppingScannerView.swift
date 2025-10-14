//
//  ShoppingScannerView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI
import Combine

import SnabbleCore
import SnabbleUI

import SnabbleAssetProviding
import CameraZoomWheel

public struct ScannerOverlay: View {
    @Binding public var offset: CGFloat
    
    @State var overlay: SwiftUI.Image = Asset.image(named: "SnabbleSDK/barcode-overlay")!
    
    public init(offset: Binding<CGFloat>) {
        self._offset = offset
    }
    
    public var body: some View {
        VStack {
            Spacer()
            overlay
                .padding(.bottom, offset)
            Spacer()
        }
    }
}

struct ShoppingScannerView: View {
    @SwiftUI.Environment(\.safeAreaInsets) var insets
    @ObservedObject var model: Shopper
    @Binding var minHeight: CGFloat
    
    @State private var topMargin: CGFloat = ScannerCartView.TopMargin
    @State private var showHud: Bool = false
    @State private var zoomLevel: CGFloat = 1
    @State private var zoomSteps: [ZoomStep] = ZoomStep.defaultSteps
    @State private var position: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            BarcodeScannerView(detector: model.barcodeManager.barcodeDetector)
            ScannerOverlay(offset: $minHeight)
            ZoomControl(zoomLevel: $zoomLevel, steps: zoomSteps)
                .offset(x: 0, y: position - 114)
                .opacity(model.scanningPaused ? 0 : 1)
            PullOverView(minHeight: $minHeight, expanded: $model.scanningPaused, paddingTop: $topMargin, position: $position) {
                ScannerCartView(model: model, minHeight: $minHeight)
            }
            if model.processing {
                ScannerProcessingView()
            }
        }
        .hud(isPresented: $showHud) {
            ScanMessageView(message: model.scanMessage, isPresented: $showHud)
        }
        .task {
            if let zoomFactor = model.barcodeManager.barcodeDetector.zoomFactor {
                zoomLevel = zoomFactor
            }
            if let steps = model.barcodeManager.barcodeDetector.zoomSteps {
                zoomSteps = steps
            }
        }
        .onChange(of: zoomLevel) {
            model.barcodeManager.barcodeDetector.zoomFactor = CGFloat(zoomLevel)
        }
        .onChange(of: showHud) {
            if !showHud {
                model.scanMessage = nil
                withAnimation {
                    topMargin -= 60
                }
            } else {
                withAnimation {
                    topMargin += 60
                }
            }
        }
        .onReceive(model.$scanMessage) { scanMessage in
            if scanMessage != nil {
                model.startScanner()
                withAnimation {
                    showHud = true
                }
            }
        }
    }
}
