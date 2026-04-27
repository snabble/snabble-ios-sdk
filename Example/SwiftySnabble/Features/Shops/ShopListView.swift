//
//  ShopListView.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents
import SnabbleShops

struct ShopListView: View {
    @Environment(AppState.self) private var appState
    
    @State private var useSDKFeature: Bool = true
    
    var body: some View {
        Group {
            if useSDKFeature {
                // Showing the SDK's build-in List of shops
                ShopsView(shops: appState.shops)
            } else {
                // Showing a custom searchable list
                CustomShopListView()
            }
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $useSDKFeature) {
                    Text("Use SDK")
                }
            }
        }
    }
}


struct CustomShopListView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

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
        List {
            if let checkedInShop = appState.checkedInShop {
                Section("Checked In") {
                    ShopRow(shop: checkedInShop, isCheckedIn: true)
                }
            }
            
            Section("All Shops") {
                ForEach(filteredShops) { shop in
                    ShopRow(
                        shop: shop,
                        isCheckedIn: shop.id == appState.checkedInShop?.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.navigate(to: .shopDetail(shop), for: .shops)
                    }
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
    NavigationStack {
        ShopListView()
            .environment(AppRouter())
            .environment(AppState())
    }
}
