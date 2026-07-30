//
//  MinimalScanAndGoApp.swift
//  MinimalScanAndGo
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI
import SnabbleCore
import SnabbleTheme
import SnabbleComponents

@main
struct MinimalScanAndGoApp: App {
    @State private var shop: Shop?

    var body: some Scene {
        WindowGroup {
            Group {
                if let shop {
                    ContentView(shop: shop)
                        .actionState()
                } else {
                    ProgressView("Loading…")
                }
            }
            .task {
                await setupSnabble()
            }
        }
    }

    @MainActor
    private func setupSnabble() async {
        let config = Config(
            appId: "snabble-sdk-demo-app-oguh3x",
            secret: Snabble.Environment.production.secret,
            environment: .production
        )

        Snabble.setup(config: config) { snabble in
            guard let project = snabble.projects.first else { return }
            SnabbleCI.register(project)
            snabble.setupProductDatabase(for: project) { _ in
                Task { @MainActor in
                    shop = project.shops.first
                }
            }
        }
    }
}
