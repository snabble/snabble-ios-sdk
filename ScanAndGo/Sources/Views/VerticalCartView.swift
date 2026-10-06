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

    init(model: Shopper, configuration: ShopperConfiguration = .init(), minHeight: Binding<CGFloat>, topMargin: Binding<CGFloat>) {
        self.model = model
        self.configuration = configuration
        self._minHeight = minHeight
        self._topMargin = topMargin
    }

    var body: some View {
        @Bindable var model = self.model
        
        Group {
            ZoomControlView(model: model)
                .offset(x: 0, y: position - configuration.zoomControlOffset)
                .opacity(model.scanningPaused ? 0 : 1)

            PullOverView(minHeight: $minHeight, expanded: $model.scanningPaused, paddingTop: $topMargin, position: $position, isDragging: $isDragging) {
                CartView(model: model, configuration: configuration, minHeight: $minHeight)
                    .disabled(isDragging)
            }
        }
    }
}
