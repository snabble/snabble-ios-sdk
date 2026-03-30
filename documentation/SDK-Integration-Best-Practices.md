# Snabble iOS SDK - Integration Best Practices

**Skill for:** Building SwiftUI apps with Snabble SDK
**Target Audience:** iOS developers integrating the Snabble SDK
**Last Updated:** 2026-03-03

---

## Overview

This guide provides best practices and patterns for integrating the Snabble iOS SDK into SwiftUI applications. These patterns are extracted from the SwiftySnabble sample app and represent production-ready approaches.

**What you'll learn:**
- ✅ Modern SwiftUI integration patterns
- ✅ State management with @Observable
- ✅ Type-safe navigation
- ✅ SDK initialization and lifecycle
- ✅ Feature implementation examples

---

## Table of Contents

1. [Project Setup](#1-project-setup)
2. [App Architecture](#2-app-architecture)
3. [State Management](#3-state-management)
4. [Navigation Patterns](#4-navigation-patterns)
5. [SDK Initialization](#5-sdk-initialization)
6. [Feature Integration](#6-feature-integration)
7. [Asset Providing](#7-asset-providing)
8. [Common Patterns](#8-common-patterns)
9. [Testing](#9-testing)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Project Setup

### SPM Dependencies

Add the Snabble SDK to your `Package.swift` or Xcode project:

```swift
dependencies: [
    .package(url: "https://github.com/snabble/snabble-ios-sdk.git", from: "1.0.0")
]
```

### Required Modules

For a full-featured app, import these modules:

```swift
import SnabbleCore          // Business logic, cart, products
import SnabbleTheme            // UI components (UIKit-based)
import SnabbleScanAndGo     // ShopperView (SwiftUI scan & go)
import SnabbleComponents    // SwiftUI components (HTMLView, etc.)
import SnabbleAssetProviding // Theming and branding
```

### Minimum Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16.0+

---

## 2. App Architecture

### Recommended Structure

Organize your app with feature-based architecture:

```
YourApp/
├── YourAppApp.swift               # @main entry point
├── Core/
│   ├── AppState.swift             # Centralized @Observable state
│   ├── AppRouter.swift            # Type-safe navigation
│   ├── AppAssetProvider.swift     # SDK branding
│   └── Config.swift               # SDK configuration
├── Features/
│   ├── Root/RootView.swift        # TabView container
│   ├── Dashboard/
│   ├── Shopping/
│   ├── Shops/
│   ├── Profile/
│   └── Receipts/
└── Support/
    └── Assets.xcassets
```

**Benefits:**
- Clear separation of concerns
- Easy to locate features
- Testable components
- Scalable structure

---

## 3. State Management

### Use @Observable for Centralized State

**Pattern:** Create a single source of truth for app-wide state.

```swift
// Core/AppState.swift
import SwiftUI
import SnabbleCore

@Observable
@MainActor
final class AppState {
    // SDK state
    var project: Project?
    var shops: [Shop] = []
    var checkedInShop: Shop?

    // App state
    var recentOrders: [Order] = []
    var isOnboardingComplete: Bool {
        get { UserDefaults.standard.bool(forKey: "onboardingComplete") }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingComplete") }
    }
}

// MARK: - SDK Delegate Conformance
extension AppState: CheckInManagerDelegate {
    nonisolated func checkInManager(_ checkInManager: CheckInManager,
                                   didCheckInTo shop: Shop) {
        Task { @MainActor in
            self.checkedInShop = shop
            // UI automatically updates
        }
    }

    nonisolated func checkInManager(_ checkInManager: CheckInManager,
                                   didCheckOut fromShop: Shop) {
        Task { @MainActor in
            self.checkedInShop = nil
        }
    }
}
```

### Inject via Environment

```swift
// YourAppApp.swift
@main
struct YourApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)  // Available to entire view tree
        }
    }
}

// Usage in any view
struct DashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let shop = appState.checkedInShop {
            Text("Checked in: \(shop.name)")
        }
    }
}
```

**✅ Best Practice:** Use `@MainActor` on AppState to ensure thread safety.

---

## 4. Navigation Patterns

### Type-Safe Router Pattern

**Pattern:** Create an observable router with tab-specific navigation paths and enum-based destinations.

```swift
// Core/AppRouter.swift
import SwiftUI
import SnabbleCore

@Observable
@MainActor
final class AppRouter {
    // Tab-specific navigation paths using dictionary
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

    // Push destinations (in NavigationStack)
    enum Destination: Hashable {
        case shopDetail(Shop)
        case webView(URL)
        case profile
        case receipt
    }

    // Sheet presentations
    enum SheetDestination: Identifiable {
        case onboarding
        case shopSelection

        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .shopSelection: return "shopSelection"
            }
        }
    }

    // Full-screen covers
    enum FullScreenDestination: Identifiable {
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

    // Navigation methods
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

// MARK: - View Builder
extension AppRouter {
    @ViewBuilder
    func view(for destination: Destination) -> some View {
        switch destination {
        case .shopDetail(let shop):
            ShopDetailView(shop: shop)
        case .webView(let url):
            WebView(url: url)
        case .profile:
            ProfileView()
        case .receipt(let order):
            ReceiptDetailView(order: order)
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
```

### Root View with Tab-Specific Navigation

```swift
// Features/Root/RootView.swift
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
```

**✅ Benefits:**
- **Tab-isolated navigation** - Each tab maintains its own navigation stack
- **Type-safe navigation** - Compiler prevents invalid states
- **Scalable architecture** - Easy to add new tabs without modifying router
- **State preservation** - Navigation state persists when switching tabs
- **Clean subscript syntax** - `router[.shops]` is elegant and readable
- **Centralized logic** - All navigation in one place

**Usage Examples:**
```swift
// Navigate in current tab
router.navigate(to: .shopDetail(shop))

// Navigate in specific tab
router.navigate(to: .shopDetail(shop), for: .shops)

// Present modals
router.showFullScreen(.shopping(shop))
router.showSheet(.shopSelection)

// Pop navigation
router.pop()                    // Pop in current tab
router.popToRoot(for: .shops)  // Clear entire stack in shops tab
```

---

## 5. SDK Initialization

### App Entry Point with Async Setup

```swift
// YourAppApp.swift
import SwiftUI
import SnabbleCore
import SnabbleAssetProviding

@main
struct YourApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()
    @State private var isInitialized = false

    let assetProvider = AppAssetProvider()

    init() {
        // Set asset provider before SDK setup
        Asset.provider = assetProvider
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isInitialized {
                    RootView()
                        .environment(router)
                        .environment(appState)
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
        // Load configuration
        let config = Config.production  // or .staging, .testing

        // Initialize SDK
        Snabble.setup(config: config) { snabble in
            guard let project = snabble.projects.first else {
                print("⚠️ No project found")
                return
            }

            // Setup product database
            snabble.setupProductDatabase(for: project) { result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        // Update app state
                        appState.project = project
                        appState.shops = project.shops

                        // Setup check-in manager
                        Snabble.shared.checkInManager.delegate = appState

                        // Show onboarding if needed
                        if !appState.isOnboardingComplete {
                            router.showSheet(.onboarding)
                        }

                        // Mark as initialized
                        isInitialized = true

                    case .failure(let error):
                        print("❌ Database setup failed: \(error)")
                    }
                }
            }
        }
    }
}
```

### Configuration

```swift
// Core/Config.swift
import SnabbleCore

enum Config {
    static let production = SnabbleConfiguration(
        appID: "your-app-id",
        appSecret: "your-app-secret",
        appName: "Your App",
        environment: .production
    )

    static let staging = SnabbleConfiguration(
        appID: "your-app-id",
        appSecret: "your-app-secret",
        appName: "Your App (Staging)",
        environment: .staging
    )

    static let testing = SnabbleConfiguration(
        appID: "your-app-id",
        appSecret: "your-app-secret",
        appName: "Your App (Testing)",
        environment: .testing
    )
}
```

**✅ Best Practice:** Use `.task` modifier for initialization, not `onAppear`.

---

## 6. Feature Integration

### Shopping Feature (Scan & Go)

**Pattern:** Use the SDK's `ShopperView` component.

```swift
// Features/Shopping/ShoppingView.swift
import SwiftUI
import SnabbleCore
import SnabbleScanAndGo

struct ShoppingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shopper: Shopper

    init(shop: Shop) {
        // Initialize Shopper with shop
        _shopper = State(initialValue: Shopper(shop: shop))
    }

    var body: some View {
        NavigationStack {
            ShopperView()  // SDK's SwiftUI component
                .environment(shopper)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// Landing view when no shop checked in
struct ShoppingLandingView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cart.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Scan & Go Shopping")
                .font(.title)
                .fontWeight(.bold)

            Text("Scan products and pay directly in the app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let shop = appState.checkedInShop {
                Button {
                    router.showFullScreen(.shopping(shop))
                } label: {
                    Text("Start Shopping")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                Button {
                    router.showSheet(.shopSelection)
                } label: {
                    Text("Select Shop")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}
```

### Shop List with Check-In

```swift
// Features/Shops/ShopListView.swift
import SwiftUI
import SnabbleCore

struct ShopListView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    var body: some View {
        List(appState.shops) { shop in
            Button {
                router.navigate(to: .shopDetail(shop))
            } label: {
                ShopRowView(
                    shop: shop,
                    isCheckedIn: appState.checkedInShop?.id == shop.id
                )
            }
        }
        .navigationTitle("Shops")
    }
}

struct ShopRowView: View {
    let shop: Shop
    let isCheckedIn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundColor(isCheckedIn ? .green : .blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(shop.name)
                        .font(.headline)

                    if isCheckedIn {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Text(shop.street)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let city = shop.city {
                    Text(city)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ShopDetailView: View {
    let shop: Shop
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Shop info
                VStack(alignment: .leading, spacing: 8) {
                    Text(shop.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Label(shop.street, systemImage: "mappin.circle.fill")
                        .foregroundColor(.secondary)
                }
                .padding()

                // Check-in button
                Button {
                    Snabble.shared.checkInManager.checkIn(shop: shop)
                    dismiss()
                } label: {
                    Label("Check In", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(appState.checkedInShop?.id == shop.id)
            }
        }
        .navigationTitle("Shop Details")
    }
}
```

### Receipts/Orders List

**Pattern:** Use the SDK's built-in `ReceiptsListScreen` component with `PurchasesViewModel`.

```swift
// Features/Receipts/ReceiptsView.swift
import SwiftUI
import SnabbleTheme

struct ReceiptsView: View {
    @State private var model = PurchasesViewModel()

    var body: some View {
        ReceiptsListScreen(model: model)  // SDK's SwiftUI component
            .navigationTitle("Receipts")
            .refreshable {
                model.load()
            }
    }
}
```

**✅ Benefits:**
- Pre-built UI with SDK styling
- Automatic receipt fetching and caching
- Built-in empty state handling
- Pull-to-refresh support
- Unread receipt badge support

**Alternative:** For custom UI, you can create your own view:

```swift
// Custom implementation (if needed)
struct CustomReceiptsView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var model = PurchasesViewModel()

    var body: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                ProgressView()
            case .loaded(let purchases):
                if purchases.isEmpty {
                    ContentUnavailableView(
                        "No Receipts",
                        systemImage: "receipt",
                        description: Text("Your purchase receipts will appear here")
                    )
                } else {
                    List(purchases, id: \.id) { purchase in
                        Button {
                            // Navigate to detail view
                        } label: {
                            ReceiptRowView(purchase: purchase)
                        }
                    }
                }
            case .failed(let error):
                ContentUnavailableView(
                    "Error Loading Receipts",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            }
        }
        .navigationTitle("Receipts")
        .task {
            model.load()
        }
        .refreshable {
            model.load()
        }
    }
}
```

### Profile with HTML Content

```swift
// Features/Profile/ProfileView.swift
import SwiftUI
import SnabbleCore
import SnabbleComponents

struct ProfileView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            Section {
                ProfileHeaderView()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section("Shopping") {
                NavigationLink {
                    ReceiptsView()
                } label: {
                    ProfileRow(
                        icon: "receipt.fill",
                        title: "Receipts",
                        color: .orange
                    )
                }
            }

            Section("Settings") {
                NavigationLink {
                    HTMLContentView(title: "Terms", htmlFileName: "terms")
                } label: {
                    ProfileRow(
                        icon: "doc.text.fill",
                        title: "Terms & Conditions",
                        color: .green
                    )
                }

                NavigationLink {
                    HTMLContentView(title: "Imprint", htmlFileName: "imprint")
                } label: {
                    ProfileRow(
                        icon: "info.circle.fill",
                        title: "Imprint",
                        color: .gray
                    )
                }
            }
        }
        .navigationTitle("Profile")
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.gradient)
                )

            Text(title)
                .font(.body)
        }
    }
}

// HTML viewer using SDK component
struct HTMLContentView: View {
    let title: String
    let htmlFileName: String
    @State private var htmlContent: String?

    var body: some View {
        Group {
            if let htmlContent {
                SnabbleComponents.HTMLView(string: htmlContent)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(title)
        .task {
            await loadHTML()
        }
    }

    private func loadHTML() async {
        guard let url = Bundle.main.url(forResource: htmlFileName, withExtension: "html"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        htmlContent = content
    }
}
```

---

## 7. Asset Providing

### Implement AssetProviding Protocol

```swift
// Core/AppAssetProvider.swift
import UIKit
import SnabbleAssetProviding

final class AppAssetProvider: AssetProviding {
    // Return nil to use SDK defaults, or customize
    public func primaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? {
        nil  // SwiftUI apps typically don't need this
    }

    public func secondaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? {
        nil
    }

    public func color(named name: String, domain: Any?) -> UIColor? {
        UIColor(named: name)  // Looks in your app's asset catalog
    }

    public func image(named name: String, domain: Any?) -> UIImage? {
        UIImage(named: name)
    }

    public func font(style: SnabbleAssetProviding.FontStyle,
                    textStyle: UIFont.TextStyle,
                    domain: Any?) -> UIFont? {
        // Return custom fonts, or nil for system fonts
        nil
    }
}
```

### Register Provider

```swift
// In YourAppApp.swift init()
init() {
    Asset.provider = AppAssetProvider()
}
```

---

## 8. Common Patterns

### Loading View

```swift
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
```

### Empty State

```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: icon,
            description: Text(message)
        )
    }
}

// Usage
EmptyStateView(
    icon: "cart",
    title: "No Items",
    message: "Your shopping cart is empty"
)
```

### Error Handling

```swift
extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        alert(
            "Error",
            isPresented: .constant(error.wrappedValue != nil),
            presenting: error.wrappedValue
        ) { _ in
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: { err in
            Text(err.localizedDescription)
        }
    }
}

// Usage
struct SomeView: View {
    @State private var error: Error?

    var body: some View {
        // ...
        .errorAlert(error: $error)
    }
}
```

---

## 9. Testing

### Test AppState

```swift
import Testing
@testable import YourApp

@Test func checkInUpdatesState() async {
    let appState = AppState()
    let mockShop = Shop(id: "test-shop", name: "Test Shop")

    // Simulate check-in
    await appState.checkInManager(
        CheckInManager.shared,
        didCheckInTo: mockShop
    )

    #expect(appState.checkedInShop?.id == "test-shop")
}
```

### Test Navigation

```swift
@Test func navigationToShopDetail() {
    let router = AppRouter()
    let mockShop = Shop(id: "test-shop", name: "Test Shop")

    router.navigate(to: .shopDetail(mockShop))

    #expect(router.path.count == 1)
}
```

---

## 10. Troubleshooting

### Common Issues

#### Issue: HTMLView shows "Ambiguous use of 'init(string:)'"

**Solution:** Qualify with module name:
```swift
SnabbleComponents.HTMLView(string: htmlContent)
```

#### Issue: CheckInManager delegate not called

**Solution:** Ensure delegate is set after SDK initialization:
```swift
Snabble.setup(config: config) { snabble in
    Snabble.shared.checkInManager.delegate = appState
}
```

#### Issue: Products not found in database

**Solution:** Wait for database setup to complete:
```swift
snabble.setupProductDatabase(for: project) { result in
    // Only proceed after success
}
```

#### Issue: @Observable state not updating UI

**Solution:** Use `@State` in views:
```swift
// ✅ Correct
struct MyView: View {
    @State var viewModel = MyViewModel()
}

// ❌ Wrong
struct MyView: View {
    var viewModel = MyViewModel()  // Won't observe changes
}
```

#### Issue: Cart items don't appear when first item is added

**Root Cause:** Computed properties depending on non-observable nested objects won't trigger SwiftUI updates.

**Solution:** Make computed properties depend on @Observable properties:
```swift
// ❌ Wrong - depends on non-observable nested property
var cartIsEmpty: Bool {
    self.shoppingCart.numberOfItems == 0  // shoppingCart is not @Observable
}

// ✅ Correct - depends on observable property
var cartIsEmpty: Bool {
    self.items.isEmpty  // items is @Observable array
}
```

**Related Fix:** In `ShoppingCartViewModel.swift`, change line 594-595 from `self.numberOfItems == 0` to `self.items.isEmpty`.

#### Issue: Price text flickering during cart updates

**Root Cause:** Empty `Text("")` elements cause layout shifts when SwiftUI re-renders because empty strings have different heights than formatted prices.

**Solution 1:** Use `.opacity()` modifier to hide empty text while preserving layout space:
```swift
// ❌ Wrong - causes flickering
Text(priceString ?? "")

// ✅ Correct - no flickering
Text(priceString ?? "")
    .opacity(priceString != nil ? 1 : 0)
```

**Solution 2:** Use placeholder text with same dimensions as actual content:
```swift
// ❌ Wrong - "" has different height than "0,00 €"
Text(totalString)

// ✅ Correct - placeholder maintains layout dimensions
Text(totalString.isEmpty ? "0,00 €" : totalString)
    .opacity(totalString.isEmpty ? 0.0 : 1.0)
```

**Related Fixes:**
- `CartItemView.swift:69,77` - Item price flickering (Solution 1)
- `ShoppingCartFooterView.swift:45` - Cart total flickering (Solution 1)
- `CheckoutView.swift:44,48` - Checkout total flickering (Solution 2)

---

## Summary

### Key Takeaways

1. **Use @Observable** for centralized state management
2. **Type-safe navigation** with router pattern
3. **Initialize SDK** in `.task` modifier on WindowGroup
4. **Leverage SDK components** like ShopperView, HTMLView
5. **Implement AssetProviding** for custom branding
6. **Follow Swift 6** concurrency best practices with @MainActor

### Reference Implementation

See the complete SwiftySnabble sample app in:
`/Example/SwiftySnabble/`

### Further Reading

- [SDK Architecture Guide](SDK-Architecture.md)
- [Sample App Comparison](Sample-App-Comparison.md)
- [Swift 6 Migration Plan](Swift-6-Migration-Plan.md)

---

**Need Help?**
- Check the sample app code in `/Example/SwiftySnabble/`
- Review SDK documentation
- Contact Snabble support

**Last Updated:** 2026-03-03
