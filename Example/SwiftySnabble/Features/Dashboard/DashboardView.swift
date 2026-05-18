//
//  DashboardView.swift
//  Snabble Sample App
//
//  Created by Uwe Tilemann on 02.03.26.
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents
import SnabbleAssetProviding

struct DashboardView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section - Eingecheckter Shop
                if let shop = appState.checkedInShop {
                    CheckedInShopCard(shop: shop)
                } else {
                    SelectShopCard()
                }

                // Quick Actions Grid
                QuickActionsGrid()
            }
            .padding()
        }
        .navigationTitle("Snabble")
        .background(Color(.systemGroupedBackground))
    }
}

struct QuickActionsGrid: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickActionCard(
                    icon: "cart.fill",
                    title: "Shopping",
                    color: .blue
                ) {
                    if let shop = appState.checkedInShop {
                        router.showFullScreen(.shopping(shop))
                    } else {
                        router.showSheet(.shopSelection)
                    }
                }

                QuickActionCard(
                    icon: "receipt.fill",
                    title: "Receipts",
                    color: .orange
                ) {
                    router.navigate(to: .receipt)
                }

                QuickActionCard(
                    icon: "storefront.fill",
                    title: "Shops",
                    color: .purple
                ) {
                    router.showSheet(.shopSelection)
                }

                QuickActionCard(
                    icon: "person.fill",
                    title: "Profile",
                    color: .green
                ) {
                    router.navigate(to: .profile)
               }
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: LocalizedStringKey
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(color.gradient)
                    )

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(AppRouter())
            .environment(AppState())
    }
}
