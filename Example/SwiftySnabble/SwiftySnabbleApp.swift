//
//  SwiftySnabbleApp.swift
//  SwiftySnabble
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleComponents
import SnabbleTheme
import SnabbleOnboarding
import SnabbleShops
import SnabbleScanAndGo

@main
struct SwiftySnabbleApp: App {
    
    @State private var router = AppRouter()
    @State private var appState = AppState()
    @State private var isInitialized = false

    let provider = AppAssetProvider()
    
    init() {
        Asset.provider = provider
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isInitialized {
                    RootView()
                        .environment(router)
                        .environment(appState)
                        .shopperActions()
                } else {
                    LoadingView()
                }
            }
            .task {
                await setupSnabble()
            }
        }
    }

    @MainActor
    private func setupSnabble() async {
        let config = Config.config(for: DeveloperMode.environmentMode)

        Snabble.setup(config: config) { snabble in
            guard let project = snabble.projects.first else {
                fatalError("project initialization failed - make sure APPID and APPSECRET are valid")
            }

            SnabbleCI.register(project)
            
            Task { @MainActor in
                for await shop in snabble.checkInManager.shopStream {
                    appState.checkedInShop = shop
                }
            }
            snabble.checkInManager.startUpdating()

            snabble.setupProductDatabase(for: project) { _ in
                Task { @MainActor in
                    appState.project = project
                    appState.shops = project.shops

                    // Check for developer check-in
                    snabble.checkInManager.verifyDeveloperCheckin()
                    appState.checkedInShop = snabble.checkInManager.shop

                    isInitialized = true

                    // Show onboarding if required
                    if Onboarding.isRequired || UserDefaults.standard.bool(forKey: "io.snabble.sample.showOnboarding") {
                        router.presentedSheet = .onboarding
                    }
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
