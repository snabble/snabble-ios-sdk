//
//  ShopSelectionView.swift
//  SwiftySnabble
//
//  Created by Uwe Tilemann on 02.03.26.
//

import SwiftUI

import SnabbleCore

struct ShopSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List(appState.shops) { shop in
                Button {
                    appState.checkedInShop = shop
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shop.name)
                            .font(.headline)

                        Text(shop.street)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Shops")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
