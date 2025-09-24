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
    @State public var model: Shopper
    @AppStorage(UserDefaults.scanningDisabledKey) var expanded: Bool = false
    
    @State private var showSearch: Bool = false
    @State private var showError: Bool = false
    @State private var minHeight: CGFloat = 0
    @State private var isPresenting: Bool = false
    
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    public init(model: Shopper) {
        self._model = State(initialValue: model)
    }
    
    public var body: some View {
        ShoppingScannerView(minHeight: $minHeight)
            .environment(model)
            .animation(.easeInOut, value: model.scannedItem)
            .navigationDestination(isPresented: $isPresenting) {
                model.navigationDestination(isPresented: $isPresenting)
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
            .onChange(of: model.isNavigating) { old, isNavigating in
                isPresenting = isNavigating
            }
            .onChange(of: model.errorMessage) { old, message in
                if message != nil {
                    model.startScanner()
                    withAnimation {
                        showError = true
                    }
                }
            }
            .onChange(of: model.scannedItem) { old, item in
                if let item {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        model.addScannedItem(item)
                        model.scannedItem = nil
                        model.startScanner()
                   }
                }
            }
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
}
