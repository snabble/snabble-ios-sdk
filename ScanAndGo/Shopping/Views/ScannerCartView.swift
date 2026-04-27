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
import SnabbleCart

struct ScannerCartView: View {
    let model: Shopper

    static let TopMargin = CGFloat(20)

    @Binding var minHeight: CGFloat

    @State private var compactMode: Bool = true

    @ScaledMetric private var barHeight = CGFloat(74)
    @ScaledMetric private var visibleRowHeight = CGFloat(72)
    let offset: CGFloat

    init(model: Shopper, minHeight: Binding<CGFloat>, offset: CGFloat = 0) {
        self.model = model
        self._minHeight = minHeight
        self.offset = offset
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CheckoutView(model: model)
            ShoppingCartView(cartModel: model.cartModel, compactMode: compactMode)
            // Without this Spacer(), we have a transparent background
            Spacer(minLength: 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .snabbleCartUpdated)) { _ in
            update()
        }
        .onChange(of: model.cartModel.items) {
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
        minHeight = barHeight + offset + (count == 0 ? 0 : (count > 1 ? avg + avg : avg))
    }
}
