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

    /// Driven by the aspect ratio of the available space, not by size class or device
    /// orientation: when it is wider than tall (landscape iPhone, iPad, an unfolded foldable
    /// held sideways), the cart is shown as its own pane next to the scanner. Otherwise the
    /// scanner uses the full space with the pull-over drawer. Follows window resizing.
    @State private var isDetailVisibleAlongside: Bool = false

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
                if #available(iOS 27.1, *) {
                    // A split arrangement divides the space along the fold when a foldable
                    // device is partially open, instead of a fixed scanner width.
                    ArrangementView {
                        scannerContent
                    } secondary: {
                        detailCartContent
                    }
                    .arrangementViewStyle(.split.axes(.horizontal))
                } else {
                    HStack(spacing: 0) {
                        scannerContent
                            .frame(minWidth: 320, maxWidth: 400)

                        detailCartContent
                    }
                }
            } else {
                scannerContent
            }
        }
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width > proxy.size.height
        } action: { isWide in
            isDetailVisibleAlongside = isWide
        }
        // Reset only when switching between drawer and side-by-side layout. Resetting in
        // onAppear would also fire when popping back from a pushed destination, where the
        // still-alive ScannerCartView has no reason to re-measure and minHeight stays 0.
        .onChange(of: isDetailVisibleAlongside) {
            minHeight = 0
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

    private var detailCartContent: some View {
        GeometryReader { reader in
            CartView(model: model, minHeight: $detailMinHeight)
                .onAppear {
                    detailMinHeight = reader.size.height
                }
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
    }
}
