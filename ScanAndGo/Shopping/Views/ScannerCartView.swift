//
//  ScannerCartView.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI
import Combine

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

struct ScannerCartView: View {
    static let BarHeight = CGFloat(74)
    static let VisibleRowHeight = CGFloat(80)
    static let TopMargin = CGFloat(20)

    @ObservedObject var model: Shopper
    @Binding var minHeight: CGFloat
    
    @State private var compactMode: Bool = true

    @State var cancellables = Set<AnyCancellable>()

    init(model: Shopper,
         minHeight: Binding<CGFloat>
    ) {
        self.model = model
        self._minHeight = minHeight
        
        NotificationCenter.default.publisher(for: .snabbleCartUpdated)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
            })
            .store(in: &cancellables)
    }
    var body: some View {
        VStack(spacing: 0) {
            CheckoutView(model: model)
            SnabbleUI.ShoppingCartView(cartModel: model.cartModel, compactMode: compactMode)
            // Without this Spacer(), we have a transparent background
            Spacer(minLength: 1)
        }
//        .background(.thinMaterial)
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
        let avg = Self.VisibleRowHeight

        // swiftlint:disable:next empty_count
        minHeight = Self.BarHeight + (count == 0 ? 0 : (count > 1 ? avg + avg / 2 : avg))
   }
}
