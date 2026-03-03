//
//  AppRouter.swift
//  Snabble Sample App
//
//  Copyright (c) 2026 snabble GmbH. All rights reserved.
//

import SwiftUI

import SnabbleCore

@Observable
@MainActor
final class AppRouter {
    private var paths: [AppTab: NavigationPath] = [:]
    
    subscript(tab: AppTab) -> NavigationPath {
        get { paths[tab] ?? NavigationPath() }
        set { paths[tab] = newValue }
    }
    
    var selectedTab: AppTab
    var presentedSheet: SheetDestination?
    var presentedFullScreen: FullScreenDestination?

    enum AppTab {
        case start, shops, shopping, receipts, profile
    }
    
    enum Destination: Hashable {
        case shopDetail(Shop)
        case webView(URL)
        case profile
        case receipt
    }

    enum SheetDestination: Swift.Identifiable {
        case onboarding
        case shopSelection

        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .shopSelection: return "shopSelection"
            }
        }
    }

    enum FullScreenDestination: Swift.Identifiable {
        case shopping(Shop)

        var id: String {
            switch self {
            case .shopping(let shop): return "shopping-\(shop.id)"
            }
        }
    }
    
    init(selectedTab: AppTab = .start) {
        self.selectedTab = selectedTab
    }
    
    func navigate(to destination: Destination, for tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        var path = paths[targetTab] ?? NavigationPath()
        path.append(destination)
        paths[targetTab] = path
    }
    
    func pop(for tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        guard var path = paths[targetTab], !path.isEmpty else { return }
        path.removeLast()
        paths[targetTab] = path
    }

    func popToRoot(for tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        paths[targetTab] = NavigationPath()
    }

    func showSheet(_ sheet: SheetDestination) {
        presentedSheet = sheet
    }

    func showFullScreen(_ destination: FullScreenDestination) {
        presentedFullScreen = destination
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }
}

extension AppRouter {
    @ViewBuilder
    func view(for destination: Destination) -> some View {
        switch destination {
        case .shopDetail(let shop):
            ShopDetailView(shop: shop)
        case .webView(let url):
            WebViewWrapper(url: url)
        case .profile:
            ProfileView()
        case .receipt:
            ReceiptsView()
        }
    }

    @ViewBuilder
    func view(for sheet: SheetDestination) -> some View {
        switch sheet {
        case .onboarding:
            OnboardingViewWrapper()
        case .shopSelection:
            ShopSelectionView()
        }
    }

    @ViewBuilder
    func view(for fullScreen: FullScreenDestination) -> some View {
        switch fullScreen {
        case .shopping(let shop):
            ShoppingView(shop: shop)
        }
    }
}

struct WebViewWrapper: View {
    let url: URL

    var body: some View {
        Text("WebView: \(url.absoluteString)")
            .navigationTitle("Web")
    }
}

