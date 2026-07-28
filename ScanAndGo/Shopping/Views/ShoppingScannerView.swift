//
//  ShoppingScannerView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleCore

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
            HStack {
                Spacer()
                overlay
                Spacer()
            }
            .padding(.bottom, offset)
            Spacer()
        }
    }
}

struct ShoppingScannerView: View {
    let model: Shopper
    
    let configuration: ShopperConfiguration
    
    @State private var topMargin: CGFloat = ScannerCartView.TopMargin
    @State private var showHud: Bool = false
    @State private var zoomLevel: CGFloat = 1
    @State private var zoomSteps: [ZoomStep] = ZoomStep.defaultSteps
    @State private var position: CGFloat = 0
    @State private var scanMessage: ScanMessage?
    @State private var isDragging: Bool = false
    @State private var minHeight: CGFloat = 0

    init(model: Shopper, configuration: ShopperConfiguration = .init()) {
        self.model = model
        self.configuration = configuration
    }
    
    var body: some View {
        @Bindable var model = self.model
        
        ZStack(alignment: .top) {
            BarcodeScannerView(detector: model.barcodeManager.barcodeDetector)
            ScannerOverlay(offset: $minHeight)
                .background {
                    if model.barcodeManager.barcodeDetector.previewLayer == nil {
                        LinearGradient(
                            colors: [Color.projectPrimary(), .white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            ZoomControl(zoomLevel: $zoomLevel, steps: zoomSteps)
                .offset(x: 0, y: position - configuration.zoomControlOffset)
                .opacity(model.scanningPaused || position == 0 ? 0 : 1)
            
            PullOverView(minHeight: $minHeight, expanded: $model.scanningPaused, paddingTop: $topMargin, position: $position, isDragging: $isDragging) {
                ScannerCartView(model: model, minHeight: $minHeight, offset: PullView.contentTopPadding + configuration.drawerOffset)
                    .disabled(isDragging)
            }
            .opacity(model.barcodeManager.barcodeDetector.state != .idle ? 1 : 0)
            .allowsHitTesting(model.barcodeManager.barcodeDetector.state != .idle)
            if model.processing || position == 0 {
                ScannerProcessingView()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .hud(isPresented: $showHud) {
            ScanMessageView(message: scanMessage, isPresented: $showHud)
        }
        .task {
            if let zoomFactor = model.barcodeManager.barcodeDetector.zoomFactor {
                zoomLevel = zoomFactor
            }
            if let steps = model.barcodeManager.barcodeDetector.zoomSteps {
                zoomSteps = steps
            }
        }
        // Syncs detector → view: fires when camera becomes available and setRecommendedZoomFactor() runs
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
        .onChange(of: model.barcodeManager.barcodeDetector.state) { _, state in
            if state == .ready, model.scanningActivated && !model.scanningPaused {
                model.startScanner()
            }
        }
        .onChange(of: model.scanMessage) { _, newValue in
            if newValue != nil {
                self.scanMessage = newValue
                model.startScanner()
                showHud = true
            }
        }
        .task(id: showHud) {
            guard showHud else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            showHud = false
        }
    }
}
