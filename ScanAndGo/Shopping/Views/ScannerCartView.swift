//
//  ScannerCartView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleCart

struct ScannerCartView: View {
    static let TopMargin = CGFloat(20)

    let model: Shopper
    @Binding var minHeight: CGFloat
    let offset: CGFloat

    @State private var compactMode: Bool = true

    @ScaledMetric private var barHeight = CGFloat(128)
    @ScaledMetric private var visibleRowHeight = CGFloat(99)

    init(model: Shopper, minHeight: Binding<CGFloat>, offset: CGFloat = 0) {
        self.model = model
        self._minHeight = minHeight
        self.offset = offset
    }

    var body: some View {
        VStack(spacing: 0) {
            CartCheckoutBarView(model: model)
            ShoppingCartView(cartModel: model.cartModel, compactMode: compactMode)
            // Without this Spacer(), we have a transparent background
            Spacer(minLength: 1)
        }
        .animation(.default, value: minHeight)
        .onAppear {
            update()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: .snabbleCartUpdated) {
                update()
            }
        }
        .onChange(of: model.cartModel.items) {
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
