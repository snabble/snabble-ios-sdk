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
    @Environment(Shopper.self) var model
    
    static let TopMargin = CGFloat(20)

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
            SnabbleUI.ShoppingCartView(cartModel: model.cartModel, compactMode: compactMode)
            // Without this Spacer(), we have a transparent background
            Spacer(minLength: 1)
        }
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
