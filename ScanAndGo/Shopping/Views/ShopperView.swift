//
//  ShopperView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 21.06.24.
//

import SwiftUI

import SnabbleAssetProviding
import SnabbleComponents

/// A view that manages the shopping session for a user, integrating with the Shopper model to handle barcode scanning, displaying scan messages, and error handling.
public struct ShopperView: View {
    @ObservedObject public var model: Shopper
    @AppStorage(UserDefaults.scanningDisabledKey) var expanded: Bool = false
    
    @State private var showSearch: Bool = false
    @State private var showError: Bool = false
    @State private var showBundleSelection: Bool = false
    
    @State private var minHeight: CGFloat = 0
    @State private var bundles: [BarcodeManager.ScannedItem] = []
    
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    public init(model: Shopper) {
        self.model = model
    }
    
    public var body: some View {
        ShoppingScannerView(model: model, minHeight: $minHeight)
            .edgesIgnoringSafeArea(.bottom)
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
            .onReceive(model.$errorMessage) { message in
                if message != nil {
                    model.startScanner()
                    withAnimation {
                        showError = true
                    }
                }
            }
            .onReceive(model.$bundles) { bundles in
                self.bundles = bundles
            }
            .onReceive(model.$scannedItem) { item in
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
            }
    }
    
    private func selectItem(_ item: BarcodeManager.ScannedItem?) {
        defer {
            model.scannedItem = nil
            model.startScanner()
        }
        guard let item else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            model.addScannedItem(item)
        }
    }
}
