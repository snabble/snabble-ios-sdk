//
//  ContentView.swift
//  MinimalScanAndGo
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI
import SnabbleCore
import SnabbleScanAndGo
import SnabbleReceipts
import SnabbleAssetProviding

struct ContentView: View {
    let shop: Shop
    @State private var showShopper = false
    @State private var receiptsModel = PurchasesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ShopCard(shop: shop) {
                    showShopper = true
                }
                .padding()

                Divider()

                ReceiptsListScreen(
                    model: receiptsModel,
                    useBuiltInNavigation: false,
                    emptyView: ContentUnavailableView {
                        Label("No Orders Yet", systemImage: "cart")
                    } description: {
                        Text("Start your first shopping session!")
                    }
                )
            }
            .navigationTitle("Snabble")
        }
        .fullScreenCover(isPresented: $showShopper) {
            ShoppingScreen(shop: shop)
        }
    }
}

private struct ShopCard: View {
    let shop: Shop
    let onStartShopping: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.tint)
                Text(shop.name)
                    .font(.headline)
                Spacer()
            }

            Button("Start Shopping", action: onStartShopping)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ShoppingScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shopper: Shopper

    init(shop: Shop) {
        _shopper = State(initialValue: Shopper(shop: shop))
    }

    var body: some View {
        NavigationStack {
            ShopperView(model: shopper, configuration: .init(drawerOffset: 20))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fertig") { dismiss() }
                    }
                }
        }
    }
}
