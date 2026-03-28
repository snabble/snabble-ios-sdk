//
//  RootView.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleTheme

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router[.start]) {
                DashboardView()
                    .navigationDestination(for: AppRouter.Destination.self) { destination in
                        router.view(for: destination)
                    }
            }
            .tabItem {
                Label("Start", systemImage: "house.fill")
            }
            .tag(AppRouter.AppTab.start)

            NavigationStack(path: $router[.shops]) {
                ShopListView()
                    .navigationDestination(for: AppRouter.Destination.self) { destination in
                        router.view(for: destination)
                    }
            }
            .tabItem {
                Label("Shops", systemImage: "storefront.fill")
            }
            .tag(AppRouter.AppTab.shops)

            NavigationStack(path: $router[.shopping]) {
                ShoppingLandingView()
                    .navigationDestination(for: AppRouter.Destination.self) { destination in
                        router.view(for: destination)
                    }
            }
            .tabItem {
                Label("Shopping", systemImage: "cart.fill")
            }
            .tag(AppRouter.AppTab.shopping)

            NavigationStack(path: $router[.receipts]) {
               ReceiptsView()
                   .navigationDestination(for: AppRouter.Destination.self) { destination in
                       router.view(for: destination)
                   }
            }
            .tabItem {
                Label("Receipts", systemImage: "receipt.fill")
            }
            .tag(AppRouter.AppTab.receipts)

            NavigationStack(path: $router[.profile]) {
                ProfileView()
                    .navigationDestination(for: AppRouter.Destination.self) { destination in
                        router.view(for: destination)
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(AppRouter.AppTab.profile)
        }
        .sheet(item: $router.presentedSheet) { sheet in
            router.view(for: sheet)
        }
        .fullScreenCover(item: $router.presentedFullScreen) { destination in
            router.view(for: destination)
        }
    }
}

#Preview {
    RootView()
        .environment(AppRouter())
        .environment(AppState())
}
