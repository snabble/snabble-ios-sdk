//
//  CartView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

struct CartView: View {
    let model: Shopper
    let configuration: ShopperConfiguration

    @Binding var minHeight: CGFloat

    @State private var trailingInset: CGFloat = 0

    init(model: Shopper, configuration: ShopperConfiguration = .init(), minHeight: Binding<CGFloat>) {
        self.model = model
        self.configuration = configuration
        self._minHeight = minHeight
    }

    var body: some View {
        ScannerCartView(model: model, minHeight: $minHeight, offset: PullView.contentTopPadding + configuration.drawerOffset)
            .opacity(model.barcodeManager.barcodeDetector.state != .idle ? 1 : 0)
            .allowsHitTesting(model.barcodeManager.barcodeDetector.state != .idle)
    }
}
