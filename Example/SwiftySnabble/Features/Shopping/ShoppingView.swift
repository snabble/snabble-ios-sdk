//
//  ShoppingView.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore
import SnabbleScanAndGo
import SnabbleComponents

struct ShoppingLandingView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "cart.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Scan & Go Shopping")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Scan products and pay directly in the app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                if let shop = appState.checkedInShop {
                    PrimaryButtonView(title: String(localized: "Start Shopping")) {
                        router.showFullScreen(.shopping(shop))
                    }
                    .padding(.horizontal)

                    Text("at \(shop.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    SecondaryButtonView(title: String(localized: "Select Shop")) {
                        router.showSheet(.shopSelection)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Shopping")
    }
}

struct ShoppingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shopper: Shopper

    init(shop: Shop) {
        _shopper = State(initialValue: Shopper(shop: shop))
    }

    var body: some View {
        NavigationStack {
            ShopperView()
                .environment(shopper)
                .actionState()
        }
    }
}

#Preview {
    ShoppingLandingView()
        .environment(AppRouter())
        .environment(AppState())
}
