//
//  ReceiptsView.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleReceipts
import SnabbleAssetProviding

struct ReceiptsView: View {
    @State private var model = PurchasesViewModel()
    
    var body: some View {
        ReceiptsListScreen(
            model: model,
            useBuiltInNavigation: true,
            emptyView: ContentUnavailableView {
                Label(Asset.localizedString(forKey: "Snabble.Receipts.noReceipts"), systemImage: "receipt.fill")
            } description: {
                Text("Happy Shopping!")
            }
        )
        .navigationTitle("Receipts")
        .refreshable {
            model.load()
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptsView()
    }
}
