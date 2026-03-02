//
//  ReceiptsView.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleUI

struct ReceiptsView: View {
    @State private var model = PurchasesViewModel()
    
    var body: some View {
        ReceiptsListScreen(model: model)
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
