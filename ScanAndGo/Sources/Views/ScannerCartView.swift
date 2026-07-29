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

    // Accessed during body evaluation so SwiftUI tracks model.cartModel.items via
    // @Observable and re-renders this view when items are added or removed.
    private var computedHeight: CGFloat {
        guard measuredBarHeight > 0 else { return 0 }
        let count = model.cartModel.items.count
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
        return measuredBarHeight + offset + rowsHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            CartCheckoutBarView(model: model)
                // fixedSize forces the bar to use its natural (ideal) height regardless of
                // how much space the VStack offers. Without this, PrimaryButtonView (which
                // has no explicit height) can cause CartCheckoutBarView to fill the entire
                // screen when position=0 on the initial render, producing a wildly large
                // measuredBarHeight that pushes the drawer to the top of the screen.
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    guard height > 0, measuredBarHeight != height else { return }
                    measuredBarHeight = height
                }
            ShoppingCartView(cartModel: model.cartModel, compactMode: compactMode) { index, height in
                guard measuredRowHeights[index] != height else { return }
                measuredRowHeights[index] = height
            }
            // layoutPriority(1) ensures ShoppingCartView claims all remaining space before
            // the Spacer below. Without this, fixedSize on the bar causes SwiftUI to split
            // the remaining space equally between ShoppingCartView and the Spacer,
            // which pushes list items toward the middle of the drawer.
            .layoutPriority(1)
            // Spacer fills remaining space so PullView's .regularMaterial background shows
            // below the cart items.
            Spacer(minLength: 1)
        }
        // Single write point. Skip the write when row heights for the current item
        // count haven't been measured yet: onPreferenceChange fires in the same layout
        // pass and will trigger another onChange with the fully-measured value, avoiding
        // two writes per frame (which causes the "tried to update multiple times" warning).
        .onChange(of: computedHeight) { _, newValue in
            let count = model.cartModel.items.count
            guard newValue > 0, minHeight != newValue else { return }
            if count >= 1 && measuredRowHeights[0] == 0 { return }
            if count >= 2 && measuredRowHeights[1] == 0 { return }
            minHeight = newValue
        }
    }
}
