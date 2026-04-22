//
//  ShopperView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 21.06.24.
//

import SwiftUI

import SnabbleAssetProviding
import SnabbleComponents

public struct ShopperConfiguration {
    let drawerOffset: CGFloat
    let showDismiss: Bool
    
    public init(
        drawerOffset: CGFloat = 0,
        showDismiss: Bool = true,
    ) {
        self.drawerOffset = drawerOffset
        self.showDismiss = showDismiss
    }
}

/// A view that manages the shopping session for a user, integrating with the Shopper model to handle barcode scanning, displaying scan messages, and error handling.
public struct ShopperView: View {
    @AppStorage(UserDefaults.scanningDisabledKey) var expanded: Bool = false
    @SwiftUI.Environment(\.dismiss) var dismiss

    @State private var showSearch: Bool = false
    @State private var showError: Bool = false
    @State private var showBundleSelection: Bool = false

    @State private var minHeight: CGFloat = 0
    @State private var bundles: [BarcodeManager.ScannedItem] = []

    let model: Shopper
    let configuration: ShopperConfiguration
    
    public init(model: Shopper, configuration: ShopperConfiguration = .init()) {
        self.model = model
        self.configuration = configuration
    }
    
    public var body: some View {
        @Bindable var model = model
        
        ShoppingScannerView(model: model, minHeight: $minHeight, configuration: configuration)
            .animation(.easeInOut, value: model.scannedItem)
            .navigationDestination(isPresented: $model.isNavigating) {
                model.navigationDestination(isPresented: $model.isNavigating)
            }
            .alert(Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.title"), isPresented: $showError) {
                Button(Asset.localizedString(forKey: "Snabble.ok")) {
                    model.errorMessage = nil
                }
            } message: {
                Text(model.errorMessage ?? "No errorMessage! This should not happen! 😳")
            }
            .sheet(isPresented: $showSearch) {
                BarcodeSearchView(model: model.barcodeManager) { code, format, template in
                    self.showSearch.toggle()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.25))
                        model.barcodeManager.handleScannedCode(code, withFormat: format, withTemplate: template)
                    }
                }
            }
            .onAppear {
                model.scanningActivated = true
                model.scanningPaused = expanded
            }
            .onDisappear {
                model.scanningActivated = false
            }
            .onReceive(model.barcodeManager.barcodeDetector.statePublisher) { state in
                if state == .ready, model.scanningActivated && !model.scanningPaused {
                    model.startScanner()
                }
            }
            .onChange(of: model.errorMessage) { _, message in
                if message != nil {
                    model.startScanner()
                    withAnimation {
                        showError = true
                    }
                }
            }
            .onChange(of: model.bundles) { _, bundles in
                self.bundles = bundles
            }
            .onChange(of: model.scannedItem) { _, item in
                if let item {
                    if self.bundles.isEmpty {
                        selectItem(item)
                    } else {
                        withAnimation {
                            showBundleSelection = true
                        }
                    }
                }
            }
            .alert(
                Asset.localizedString(forKey: "Snabble.Scanner.BundleDialog.headline"),
                isPresented: $showBundleSelection,
                actions: {
                    ForEach(bundles, id: \.code) { bundle in
                        Button(bundle.productName) {
                            selectItem(bundle)
                        }
                    }
                    if let item = model.scannedItem {
                        Button(item.productName) {
                            selectItem(item)
                        }
                    }
                    Button(Asset.localizedString(forKey: "Snabble.cancel")) {
                        selectItem(nil)
                    }
                }
            )
            .onChange(of: showSearch) {
                if showSearch {
                    model.stopScanner()
                } else {
                    model.startScanner()
                }
            }
            .toolbar {
                if configuration.showDismiss {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text(keyed: "Snabble.done")
                        })
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(action: {
                            model.flashlight.toggle()
                        }, label: {
                            Image(systemName: model.flashlight == true ? "flashlight.on.fill" : "flashlight.off.fill")
                        })
                        Button(action: {
                            model.stopScanner()
                            showSearch.toggle()
                        }, label: {
                            Image(systemName: "magnifyingglass")
                        })
                    }
                } else {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button(action: {
                            model.flashlight.toggle()
                        }, label: {
                            Image(systemName: model.flashlight == true ? "flashlight.on.fill" : "flashlight.off.fill")
                        })
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(action: {
                            model.stopScanner()
                            showSearch.toggle()
                        }, label: {
                            Image(systemName: "magnifyingglass")
                        })
                    }
                    
                }
            }
    }
    
    private func selectItem(_ item: BarcodeManager.ScannedItem?) {
        guard let item else {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.25))
                model.scannedItem = nil
                model.startScanner()
            }
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.25))
            model.addScannedItem(item)
            model.scannedItem = nil
            model.startScanner()
        }
    }
}
