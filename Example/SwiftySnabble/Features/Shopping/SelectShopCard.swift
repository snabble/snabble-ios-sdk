//
//  SelectShopCard.swift
//  SwiftySnabble
//
//  Created by Uwe Tilemann on 02.03.26.
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleComponents

struct SelectShopCard: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "storefront")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Shop Selected")
                .font(.headline)

            Text("Select a shop to start shopping")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            SecondaryButtonView(title: String(localized: "Select Shop")) {
                router.showSheet(.shopSelection)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

