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
    @State private var showEditor: Bool = false
    @State private var showDialog: Bool = false
    @State private var minHeight: CGFloat = 0
    
    public init(model: Shopper) {
        self.model = model
    }
    
    public var body: some View {
        ShoppingScannerView(model: model, minHeight: $minHeight)
            .animation(.easeInOut, value: model.scannedItem)
            .navigationDestination(isPresented: $showDialog) {
                model.navigationDestination(isPresented: $showDialog)
            }
            .alert(Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.title"), isPresented: $showError) {
                Button(Asset.localizedString(forKey: "Snabble.ok")) {
                    model.errorMessage = nil
                }
            } message: {
                Text(model.errorMessage ?? "No errorMessage! This should not happen! 😳")
            }
            .dialog(isPresented: $showEditor) {
                ScannedItemEditorView(model: model) {
                    showEditor = false
                }
            }
            .keyboardHeightEnvironmentValue()
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
            .onReceive(model.$errorMessage) { message in
                if message != nil {
                    model.startScanner()
                    withAnimation {
                        showError = true
                    }
                }
            }
            .onReceive(model.$scannedItem) { item in
                if item != nil {
                    withAnimation {
                        showEditor = true
                    }
                }
            }
            .onReceive(model.$controller) { controller in
                if controller != nil {
                    model.stopScanner()
                    withAnimation {
                        showDialog = true
                    }
                }
            }
            .onChange(of: showDialog) {
                if !showDialog {
                    model.controller = nil
                    model.startScanner()
                }
            }
            .onChange(of: showEditor) {
                if !showEditor {
                    model.scannedItem = nil
                    model.startScanner()
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
#if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    ShoppingManagerActionView(model: model)
                }
#endif
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        model.flashlight.toggle()
                    }, label: {
                        Image(systemName: model.flashlight == true ? "flashlight.on.fill" : "flashlight.off.fill")
                    })
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        model.stopScanner()
                        showSearch.toggle()
                    }, label: {
                        Image(systemName: "magnifyingglass")
                    })
                }
            }
            .toolbarBackground(Material.thick, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}
