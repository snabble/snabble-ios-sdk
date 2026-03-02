//
//  ShopDetailView.swift
//  SwiftySnabble
//
//  Created by Uwe Tilemann on 02.03.26.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents

struct ShopDetailView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    let shop: Shop

    var isCheckedIn: Bool {
        appState.checkedInShop?.id == shop.id
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Shop Header
                VStack(spacing: 12) {
                    Image(systemName: "storefront")
                        .font(.system(size: 60))
                        .foregroundColor(isCheckedIn ? .green : .blue)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(isCheckedIn ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        )

                    Text(shop.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if isCheckedIn {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Checked In")
                        }
                        .font(.subheadline)
                        .foregroundColor(.green)
                    }
                }
                .padding()

                // Shop Info
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "location.fill", text: shop.street)
                        InfoRow(icon: "mappin.circle.fill", text: shop.city)
                        InfoRow(icon: "number", text: shop.postalCode)
                    }
                }
                .padding(.horizontal)

                // Actions
                VStack(spacing: 12) {
                    if isCheckedIn {
                        PrimaryButtonView(title: String(localized: "Start Shopping")) {
                            router.showFullScreen(.shopping(shop))
                        }
                        .padding(.horizontal)
                    } else {
                        PrimaryButtonView(title: String(localized: "Check In at This Shop")) {
                            appState.checkedInShop = shop
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(text)
                .font(.body)
        }
    }
}
