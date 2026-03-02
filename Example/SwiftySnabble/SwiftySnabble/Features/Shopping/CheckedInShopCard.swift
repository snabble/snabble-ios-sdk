//
//  CheckedInShopCard.swift
//  SwiftySnabble
//
//  Created by Uwe Tilemann on 02.03.26.
//

import SwiftUI

import SnabbleCore
import SnabbleComponents

struct CheckedInShopCard: View {
    @Environment(AppRouter.self) private var router
    let shop: Shop

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Checked In")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(shop.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(shop.street)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }

            PrimaryButtonView(title: String(localized: "Start Shopping")) {
                router.showFullScreen(.shopping(shop))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

