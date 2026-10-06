//
//  ShoppingScannerView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleAssetProviding

struct ShoppingScannerView: View {

    let model: Shopper
    
    let configuration: ShopperConfiguration
    
    @State private var topMargin: CGFloat = ScannerCartView.TopMargin
    @State private var showHud: Bool = false
    @State private var scanMessage: ScanMessage?
    @State private var minHeight: CGFloat = 0
    @State private var detailMinHeight: CGFloat = 0
    
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .content
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// The split view only collapses on compact width, so in regular width the detail column shows the cart next to the scanner.
    private var isDetailVisibleAlongside: Bool {
        horizontalSizeClass == .regular && columnVisibility != .detailOnly
    }
    
    init(model: Shopper, configuration: ShopperConfiguration = .init()) {
        self.model = model
        self.configuration = configuration
    }
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn,
            sidebar: {
                ZStack(alignment: .top) {
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
                    
                    if !isDetailVisibleAlongside {
                        VerticalCartView(model: model, configuration: configuration, minHeight: $minHeight, topMargin: $topMargin)
                    } else {
                        VStack {
                            Spacer()
                            ZoomControlView(model: model)
                                .opacity(model.scanningPaused ? 0 : 1)
                        }
                        .onAppear {
                            minHeight = 0
                        }
                    }
                    if model.processing {
                        ScannerProcessingView()
                    }
                }
                .background {
                    BarcodeScannerView(detector: model.barcodeManager.barcodeDetector)
                }
                .ignoresSafeArea(edges: [.bottom])
                .navigationSplitViewColumnWidth(ideal: 400)
            }, detail: {
                GeometryReader { reader in
                    CartView(model: model, minHeight: $detailMinHeight)
                        .onAppear {
                            detailMinHeight = reader.size.height
                        }
                }
            }
        )
        .hud(isPresented: $showHud) {
            ScanMessageView(message: scanMessage, isPresented: $showHud)
        }
        // Syncs detector → view: fires when camera becomes available and setRecommendedZoomFactor() runs
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
