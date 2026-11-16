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
        Group {
            if #available(iOS 27.1, *) {
                // Side by side when wider than tall (split at the fold on a partially
                // open foldable), stacked otherwise.
                ArrangementView {
                    shopCard
                        .padding()
                        .frame(maxHeight: .infinity, alignment: .top)
                        // In a vertical split, keep the card at its natural height and
                        // leave the remaining space to the actions.
                        .splitArrangementFixedLayoutSize(horizontal: false, vertical: true)
                } secondary: {
                    ScrollView {
                        QuickActionsGrid()
                            .padding()
                    }
                }
                .arrangementViewStyle(.split)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        shopCard
                        QuickActionsGrid()
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Snabble")
        .background(Color(.systemGroupedBackground))
    }

    // Hero Section - Eingecheckter Shop
    @ViewBuilder
    private var shopCard: some View {
        if let shop = appState.checkedInShop {
            CheckedInShopCard(shop: shop)
        } else {
            SelectShopCard()
        }
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
