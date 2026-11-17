//
//  ShopListView.swift
//  Snabble Sample App
//
//  Created by Uwe Tilemann on 02.03.26.
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents
import SnabbleShops

/// Shows the shops as a split view: the list in the sidebar and the selected shop as detail.
/// In compact width the split view collapses into a navigation stack.
struct ShopListView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    @State private var useSDKFeature: Bool = true
    @State private var selection: Identifier<Shop>?
    @State private var shopsViewModel = ShopsViewModel(shops: [])

    var body: some View {
        NavigationSplitView {
            Group {
                if useSDKFeature {
                    // Showing the SDK's build-in List of shops
                    ShopsListView(viewModel: shopsViewModel, selection: $selection)
                } else {
                    // Showing a custom searchable list
                    CustomShopListView(selection: $selection)
                }
            }
            .navigationTitle("Shops")
            .toolbar {
                ToolbarItem {
                    Toggle(isOn: $useSDKFeature) {
                        Text("Use SDK")
                    }
                }
            }
        } detail: {
            if useSDKFeature {
                ShopsDetailView(viewModel: shopsViewModel, selection: selection)
            } else if let shop = appState.shops.first(where: { $0.id == selection }) {
                ShopDetailView(shop: shop)
            } else {
                ContentUnavailableView("Select a Shop", systemImage: "storefront")
            }
        }
        .task(id: appState.shops.map(\.id)) {
            // A fresh view model per run: its actionStream finishes once the iterating
            // task is cancelled (e.g. when switching tabs), so it can't be listened to again.
            let viewModel = ShopsViewModel(shops: appState.shops)
            shopsViewModel = viewModel
            for await shop in viewModel.actionStream {
                guard let shop = appState.shops.first(where: { $0.id == shop.id }) else { continue }
                router.showFullScreen(.shopping(shop))
            }
        }
    }
}


struct CustomShopListView: View {
    @Environment(AppState.self) private var appState
    @Binding var selection: Identifier<Shop>?

    @State private var searchText = ""

    var filteredShops: [Shop] {
        if searchText.isEmpty {
            return appState.shops
        }
        return appState.shops.filter { shop in
            shop.name.localizedCaseInsensitiveContains(searchText) ||
            shop.street.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(selection: $selection) {
            if let checkedInShop = appState.checkedInShop {
                Section("Checked In") {
                    ShopRow(shop: checkedInShop, isCheckedIn: true)
                        .tag(checkedInShop.id)
                }
            }

            Section("All Shops") {
                ForEach(filteredShops) { shop in
                    ShopRow(
                        shop: shop,
                        isCheckedIn: shop.id == appState.checkedInShop?.id
                    )
                    .tag(shop.id)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search shops")
    }
}

struct ShopRow: View {
    let shop: Shop
    let isCheckedIn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "storefront")
                .font(.title2)
                .foregroundColor(isCheckedIn ? .green : .secondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isCheckedIn ? Color.green.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(shop.name)
                        .font(.headline)

                    if isCheckedIn {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Text(shop.street)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(shop.city)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ShopListView()
        .environment(AppRouter())
        .environment(AppState())
}
