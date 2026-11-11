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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Regular width also matches large iPhones (e.g. Pro Max) in landscape - there, as on iPad
    /// or an unfolded foldable, the cart is shown as its own detail pane next to the scanner
    /// instead of the pull-over drawer used in compact width.
    private var isDetailVisibleAlongside: Bool {
        horizontalSizeClass == .regular
    }

    init(model: Shopper, configuration: ShopperConfiguration = .init()) {
        self.model = model
        self.configuration = configuration
    }

    var body: some View {
        Group {
            // NavigationSplitView is intentionally avoided here: nesting it inside the
            // outer NavigationStack (ShopperView is pushed as a destination) leaves the
            // sidebar column unrendered on the very first compact-width layout pass, and
            // only recovers after an orientation round-trip forces a relayout. A manual
            // HStack sidesteps that bug entirely since it isn't a navigation container.
            if isDetailVisibleAlongside {
                HStack(spacing: 0) {
                    scannerContent
                        .frame(minWidth: 320, maxWidth: 400)

                    GeometryReader { reader in
                        CartView(model: model, minHeight: $detailMinHeight)
                            .onAppear {
                                detailMinHeight = reader.size.height
                            }
                    }
                }
            } else {
                scannerContent
            }
        }
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

    @ViewBuilder
    private var scannerContent: some View {
        ZStack(alignment: .top) {
            // Only the camera feed and its gradient fallback bleed into the bottom safe
            // area (edge-to-edge look). The drawer below measures its drag positions
            // against this ZStack's safe-area-respecting height, so its checkout bar stays
            // above a host-provided bottom bar (e.g. a TabView's tab bar) no matter how few
            // items (or none) are in the cart - only its material background and any rows
            // beyond that are allowed to visually overflow into the ignored area below.
            Group {
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
            }
            .ignoresSafeArea(.container, edges: .bottom)

            // VerticalCartView's PullOverView contains a GeometryReader, which - like a
            // Spacer - has no intrinsic height. Wrapping it in a Spacer-VStack (as done for
            // ZoomControlView below) would make the two flexible views split the available
            // space instead of the drawer getting the full height it measures its drag
            // positions against, so it's placed as a direct ZStack child instead.
            if !isDetailVisibleAlongside {
                VerticalCartView(model: model, configuration: configuration, minHeight: $minHeight, topMargin: $topMargin)
            } else {
                VStack {
                    Spacer()
                    ZoomControlView(model: model)
                        .opacity(model.scanningPaused ? 0 : 1)
                }
            }
            if model.processing {
                ScannerProcessingView()
            }
        }
        .onAppear {
            minHeight = 0
        }
    }
}
