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
import SnabbleShops

struct ContentView: View {
    let shop: Shop
    @State private var shopsViewModel: ShopsViewModel
    @State private var showShopper = false
    @State private var navigateToShop = false
    @State private var receiptsModel = PurchasesViewModel()

    init(shop: Shop) {
        self.shop = shop
        _shopsViewModel = State(initialValue: ShopsViewModel(shops: [shop]))
    }

    var body: some View {
        NavigationStack {
            List {
                shopSection
                receiptsSection
            }
            .listStyle(.plain)
            .refreshable { receiptsModel.refresh() }
            .navigationTitle("Snabble")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToShop) {
                ShopView(shop: shop, viewModel: shopsViewModel)
            }
        }
        .fullScreenCover(isPresented: $showShopper) {
            ShoppingScreen(shop: shop)
        }
        .task {
            receiptsModel.reset()
            for await _ in shopsViewModel.actionStream {
                showShopper = true
            }
        }
    }

    @ViewBuilder
    private var shopSection: some View {
        Section("Shopping") {
            ShopCard(shop: shop, onShopTapped: { navigateToShop = true }, onStartShopping: { showShopper = true })
        }
    }

    @ViewBuilder
    private var receiptsSection: some View {
        Section("Receipts") {
            if receiptsModel.orders.isEmpty {
                Label("No orders yet – start your first shopping session!", systemImage: "cart")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(receiptsModel.orders, id: \.id) { order in
                    NavigationLink {
                        ReceiptDetailScreen(provider: order)
                            .onAppear { receiptsModel.markAsRead(receiptId: order.id) }
                    } label: {
                        ReceiptsItemView(
                            provider: order,
                            image: receiptsModel.imageFor(projectId: order.projectId),
                            showReadState: !receiptsModel.isRead(receiptId: order.id),
                            showChevron: false
                        )
                    }
                }
            }
        }
    }
}

private struct ShopCard: View {
    let shop: Shop
    let onShopTapped: () -> Void
    let onStartShopping: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onShopTapped) {
                HStack(spacing: 12) {
                    Image(systemName: "storefront.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(shop.name)
                            .font(.headline)
                        Text(shop.street)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Button(action: onStartShopping) {
                Image(systemName: "barcode.viewfinder")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.tint)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 2)
    }
}

private struct ShoppingScreen: View {
    @State private var shopper: Shopper

    init(shop: Shop) {
        _shopper = State(initialValue: Shopper(shop: shop))
    }

    var body: some View {
        NavigationStack {
            ShopperView(model: shopper, configuration: .init(drawerOffset: 20))
        }
    }
}
