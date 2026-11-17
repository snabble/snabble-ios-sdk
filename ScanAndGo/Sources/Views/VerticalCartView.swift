//
//  VerticalCartView.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

struct VerticalCartView: View {
    let model: Shopper
    let configuration: ShopperConfiguration

    @Binding var minHeight: CGFloat
    @Binding var topMargin: CGFloat

    @State private var isDragging: Bool = false
    @State private var position: CGFloat = 0
    @State private var zoomControlHeight: CGFloat = 0

    init(model: Shopper, configuration: ShopperConfiguration = .init(), minHeight: Binding<CGFloat>, topMargin: Binding<CGFloat>) {
        self.model = model
        self.configuration = configuration
        self._minHeight = minHeight
        self._topMargin = topMargin
    }

    var body: some View {
        @Bindable var model = self.model

        // ZStack, not VStack: ZoomControlView floats at a position-relative offset and
        // isn't meant to consume layout space of its own. In a VStack it would sit above
        // PullOverView and push its GeometryReader's origin down by ZoomControlView's
        // height even while hidden (opacity doesn't remove layout participation), throwing
        // off every position computed relative to that GeometryReader's frame.
        ZStack(alignment: .top) {
            ZoomControlView(model: model)
                // Anchored by its own bottom edge (not its top) so the gap to the drawer
                // above is exactly `zoomControlOffset`, regardless of its rendered height.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    zoomControlHeight = height
                }
                .offset(x: 0, y: position - configuration.zoomControlOffset - zoomControlHeight)
                .opacity(model.scanningPaused ? 0 : 1)

            PullOverView(minHeight: $minHeight, expanded: $model.scanningPaused, paddingTop: $topMargin, position: $position, isDragging: $isDragging) {
                CartView(model: model, configuration: configuration, minHeight: $minHeight)
                    .disabled(isDragging)
            }
        }
    }
}
