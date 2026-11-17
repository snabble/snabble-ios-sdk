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
    // Used until a row has been measured. A List only realizes visible rows, so while the
    // collapsed drawer has no room for a row, it never reports its height. The estimate
    // makes room for the row, which then gets measured and replaces the estimate.
    static let estimatedRowHeight = CGFloat(64)

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
        let rowHeights = measuredRowHeights.map { $0 > 0 ? $0 : Self.estimatedRowHeight }
        let rowsHeight: CGFloat
        switch count {
        case 0:
            rowsHeight = 0
        case 1:
            rowsHeight = rowHeights[0] + rowInsets
        default:
            rowsHeight = rowHeights[0] + rowHeights[1] + rowInsets * 2
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
        .navigationBarBackButtonHidden(false)
        // Single write point. Unmeasured rows contribute an estimate (see estimatedRowHeight),
        // so this may write twice: first the estimate, then the measured value.
        .onChange(of: computedHeight) { _, newValue in
            guard newValue > 0, minHeight != newValue else { return }
            minHeight = newValue
        }
    }
}
