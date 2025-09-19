//
//  ScannerCartView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI
import Combine

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

struct ScannerCartView: View {
    static let TopMargin = CGFloat(20)

    @Environment(Shopper.self) var model
    @Binding var minHeight: CGFloat

    @State private var compactMode: Bool = true

    @ScaledMetric private var barHeight = CGFloat(74)
    @ScaledMetric private var visibleRowHeight = CGFloat(58)

    init(minHeight: Binding<CGFloat>) {
        self._minHeight = minHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CheckoutView()
            SnabbleUI.ShoppingCartView(compactMode: compactMode)
                .environment(model.cartModel)
            // Without this Spacer(), we have a transparent background
            Spacer(minLength: 1)
        }
        .scrollDisabled(!model.scanningPaused)
        .onReceive(NotificationCenter.default.publisher(for: .snabbleCartUpdated)) { _ in
            update()
        }
        .task {
            update()
        }
    }
    
    func update() {
        let count = model.barcodeManager.shoppingCart.numberOfItems
        let avg = visibleRowHeight
        
        // swiftlint:disable:next empty_count
        minHeight = barHeight + (count == 0 ? 0 : (count > 1 ? avg + avg : avg))
    }
}
