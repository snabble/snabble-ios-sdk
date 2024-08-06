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

struct ScannerOverlay: View {
    @Binding var offset: CGFloat
    @State var overlay: SwiftUI.Image = Asset.image(named: "SnabbleSDK/barcode-overlay")!
    
    var body: some View {
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
    
    var body: some View {
        ZStack(alignment: .top) {
            BarcodeScannerView(manager: model.barcodeManager)
            ScannerOverlay(offset: $minHeight)
            PullOverView(minHeight: $minHeight, expanded: $model.scanningPaused, paddingTop: $topMargin) {
                ScannerCartView(model: model, minHeight: $minHeight)
            }
            if model.processing {
                ScannerProcessingView()
            }
        }
        .hud(isPresented: $showHud) {
            ScanMessageView(message: model.scanMessage, isPresented: $showHud)
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
