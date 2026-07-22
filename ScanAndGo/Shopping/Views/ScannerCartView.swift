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

    @State private var measuredBarHeight: CGFloat = 0
    @State private var measuredRowHeights: [CGFloat] = [0, 0]

    init(model: Shopper, minHeight: Binding<CGFloat>, offset: CGFloat = 0) {
        self.model = model
        self._minHeight = minHeight
        self.offset = offset
    }

    var body: some View {
        VStack(spacing: 0) {
            CartCheckoutBarView(model: model)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    measuredBarHeight = height
                    updateMinHeight()
                }
            ShoppingCartView(cartModel: model.cartModel, compactMode: compactMode) { index, height in
                measuredRowHeights[index] = height
                updateMinHeight()
            }
            // Without this Spacer(), we have a transparent background
            Spacer(minLength: 1)
        }
        .animation(.default, value: minHeight)
        .task {
            for await _ in NotificationCenter.default.notifications(named: .snabbleCartUpdated) {
                updateMinHeight()
            }
        }
        .onChange(of: model.cartModel.items) {
            updateMinHeight()
        }
    }

    func updateMinHeight() {
        guard measuredBarHeight > 0 else { return }
        let count = model.barcodeManager.shoppingCart.numberOfItems
        // listRowInsets adds 4pt top + 4pt bottom per row
        let rowInsets: CGFloat = 8
        let rowsHeight: CGFloat
        switch count {
        case 0:
            rowsHeight = 0
        case 1:
            rowsHeight = measuredRowHeights[0] + rowInsets
        default:
            rowsHeight = measuredRowHeights[0] + measuredRowHeights[1] + rowInsets * 2
        }
        minHeight = measuredBarHeight + offset + rowsHeight
    }
}
