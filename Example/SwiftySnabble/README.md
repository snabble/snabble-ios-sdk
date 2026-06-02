# SwiftySnabble - Modern SwiftUI Sample App

A modern SwiftUI-based sample app for the Snabble iOS SDK using Swift 6.2.

## 📱 Overview

SwiftySnabble is a fully SwiftUI-based sample app demonstrating best practices for integrating the Snabble SDK. It uses modern Swift 6.2 features like @Observable, async/await, and type-safe navigation.

## 🏗️ Architecture

### Directory Structure

```
SwiftySnabble/
├── Core/
│   ├── AppState.swift              # Global state management
│   ├── AppRouter.swift             # Type-safe navigation
│   ├── AppAssetProvider.swift      # SDK asset provider
│   └── SnabbleConfig.swift         # API configuration
├── Features/
│   ├── Root/
│   │   └── RootView.swift         # Main TabView
│   ├── Dashboard/
│   │   └── DashboardView.swift    # Home screen
│   ├── Shops/
│   │   ├── ShopListView.swift     # Shop list with search
│   │   ├── ShopDetailView.swift   # Shop details
│   │   └── ShopSelectionView.swift # Sheet for shop selection
│   ├── Shopping/
│   │   ├── ShoppingView.swift     # Shopping flow entry
│   │   ├── CheckedInShopCard.swift # Dashboard card
│   │   └── SelectShopCard.swift   # Empty state card
│   ├── Receipts/
│   │   └── ReceiptsView.swift     # Order history
│   ├── Profile/
│   │   ├── ProfileView.swift      # Profile screen
│   │   ├── PaymentMethodsViewWrapper.swift # Payment management
│   │   ├── EnvironmentSelectorView.swift   # Dev tools
│   │   └── HTMLContentView.swift  # Terms & Privacy
│   └── Onboarding/
│       └── OnboardingViewWrapper.swift # First-run onboarding
├── Support/
│   ├── Assets.xcassets            # Images and colors
│   ├── Localizable.xcstrings      # Localization (EN/DE)
│   ├── Onboarding.json            # Onboarding config
│   ├── terms.html                 # Terms of service
│   └── imprint.html               # Legal imprint
└── SwiftySnabbleApp.swift         # @main entry point
```

### Key Architecture Patterns

#### 1. Navigation Router Pattern

Type-safe navigation using a centralized router with tab-specific paths:

```swift
@Observable
@MainActor
final class AppRouter {
    // Tab-specific navigation paths
    private var paths: [AppTab: NavigationPath] = [:]

    subscript(tab: AppTab) -> NavigationPath {
        get { paths[tab] ?? NavigationPath() }
        set { paths[tab] = newValue }
    }

    var selectedTab: AppTab
    var presentedSheet: SheetDestination?
    var presentedFullScreen: FullScreenDestination?

    // Navigation methods
    func navigate(to destination: Destination, for tab: AppTab? = nil)
    func pop(for tab: AppTab? = nil)
    func popToRoot(for tab: AppTab? = nil)
    func showSheet(_ sheet: SheetDestination)
    func showFullScreen(_ destination: FullScreenDestination)
}
```

**Benefits:**
- Each tab maintains its own navigation stack
- Type-safe navigation destinations
- Centralized navigation logic
- Easy to test and maintain

**Usage:**
```swift
// Navigate in current tab
router.navigate(to: .shopDetail(shop))

// Navigate in specific tab
router.navigate(to: .receipt, for: .start)

// Present sheets and full screens
router.showFullScreen(.shopping(shop))
router.showSheet(.shopSelection)
```

#### 2. Global State Management

Observable state pattern for app-wide data:

```swift
@Observable
@MainActor
final class AppState {
    var project: Project?
    var shops: [Shop] = []
    var checkedInShop: Shop?
    var recentOrders: [Order] = []

    init() {
        Task {
            await loadData()
        }
    }
}
```

**Usage in views:**
```swift
@Environment(AppState.self) private var appState

var body: some View {
    if let shop = appState.checkedInShop {
        CheckedInShopCard(shop: shop)
    }
}
```

#### 3. Feature-Based Modularization

Each feature is self-contained with its own views and logic:

```
Features/
├── Dashboard/        # Home screen with quick actions
├── Shops/           # Shop browsing and selection
├── Shopping/        # Scan & Go shopping flow
├── Receipts/        # Order history
├── Profile/         # User settings
└── Onboarding/      # First-run experience
```

## 🎯 SDK Integration Best Practices

### 1. App Initialization

```swift
@main
struct SwiftySnabbleApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()
    @State private var assetProvider = AppAssetProvider()

    init() {
        setupSnabble()
    }

    private func setupSnabble() {
        // Initialize SDK
        Snabble.setup(
            appId: Config.appId,
            appSecret: Config.appSecret,
            environment: DeveloperMode.environmentMode
        )

        // Set custom asset provider
        Snabble.setAssetProvider(assetProvider)
    }
}
```

### 2. Asset Provider Integration

Custom asset provider for SDK theming:

```swift
@Observable
@MainActor
class AppAssetProvider: AssetProviding {
    public func image(named name: String) -> UIImage? {
        return UIImage(named: name)
    }

    public func color(named name: String) -> UIColor? {
        return UIColor(named: name)
    }

    public func imageDataAsset(named name: String) -> NSDataAsset? {
        return NSDataAsset(name: name)
    }
}
```

### 3. Scanner Integration

Using the SnabbleScanAndGo module:

```swift
struct ShoppingView: View {
    @State private var shopper: Shopper

    init(shop: Shop) {
        _shopper = State(initialValue: Shopper(shop: shop))
    }

    var body: some View {
        NavigationStack {
            ShopperView()
                .environment(shopper)
        }
    }
}
```

### 4. Payment Methods Management

Wrapping UIKit payment controller in SwiftUI:

```swift
struct PaymentMethodsViewWrapper: View {
    var project: SnabbleCore.Project?
    @State private var paymentVC: PaymentMethodListViewController?

    var body: some View {
        if let paymentVC, let project {
            ContainerView(viewController: paymentVC)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            paymentVC.addPaymentMethod(
                                for: project.id,
                                analyticsDelegate: nil
                            )
                        }, label: {
                            Label("Add Payment", systemImage: "plus")
                        })
                    }
                }
        } else {
            SnabbleEmptyView(
                title: "Payments.emptyMessage".localized,
                image: Image("CardPayment"),
                imageWidth: 200
            )
        }
    }
}
```

### 5. Receipts Integration

Using SDK's receipts list view:

```swift
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
```

### 6. Onboarding Configuration

JSON-based onboarding with localization:

```json
{
    "configuration": {
        "imageSource": "Onboarding/onboarding-logo"
    },
    "items": [
        {
            "imageSource": "Onboarding/onboarding-image-1",
            "text": "Onboarding.message1"
        },
        {
            "imageSource": "Onboarding/onboarding-image-2",
            "text": "Onboarding.message2"
        },
        {
            "imageSource": "Onboarding/onboarding-image-3",
            "text": "Please accept the [terms](snabble://terms.html)...",
            "link": "imprint.html",
            "customButtonTitle": "Onboarding.accept"
        }
    ]
}
```

**Localization:**
- Strings in `Onboarding.json` use localization keys
- Keys are defined in `Localizable.xcstrings`
- SDK's `OnboardingItem.attributedString` automatically localizes using `NSLocalizedString`

### 7. Localization Strategy

Using Xcode String Catalogs (`.xcstrings`):

```json
{
  "sourceLanguage": "en",
  "strings": {
    "Onboarding.message1": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Using Snabble, you scan..."
          }
        },
        "de": {
          "stringUnit": {
            "state": "translated",
            "value": "Mit Snabble scannst du..."
          }
        }
      }
    }
  }
}
```

**Benefits:**
- Single source of truth for all translations
- Xcode's built-in localization editor
- Automatic string extraction
- Type-safe localization with `String(localized:)`

## 🚀 Development

### Prerequisites

- Xcode 16.4+
- iOS 17.0+
- Swift 6.2
- Snabble API Credentials

### Build & Run

```bash
cd Example/SwiftySnabble
open SwiftySnabble.xcodeproj
# ⌘R to run
```

### Configuration

1. **API Credentials:**
   Edit `Core/SnabbleConfig.swift`:
   ```swift
   enum Config {
       static let appId = "your-app-id"
       static let appSecret = "your-app-secret"
   }
   ```

2. **Environment:**
   Switch environments in Profile tab:
   - Production
   - Staging
   - Testing

## 🎨 Design Patterns

### 1. Composition over Inheritance

Break down complex views into smaller, reusable components:

```swift
// ✅ Good - Composed views
struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let shop = appState.checkedInShop {
                    CheckedInShopCard(shop: shop)
                } else {
                    SelectShopCard()
                }
                QuickActionsGrid()
            }
        }
    }
}

// ❌ Bad - Monolithic view
struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack {
                // 200+ lines of view code...
            }
        }
    }
}
```

### 2. Environment-Based Dependency Injection

Use `@Environment` for shared dependencies:

```swift
// In root view
@main
struct SwiftySnabbleApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(router)
        }
    }
}

// In feature views
struct ShopListView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
}
```

### 3. Navigation Separation

Keep navigation logic out of business logic:

```swift
// ✅ Good - Navigation in router
router.navigate(to: .shopDetail(shop), for: .shops)

// ❌ Bad - Direct navigation in view
@State private var isShowingDetail = false
```

### 4. Async Task Management

Use structured concurrency with `.task`:

```swift
struct PaymentMethodsViewWrapper: View {
    @State private var paymentVC: PaymentMethodListViewController?

    var body: some View {
        content
            .task {
                if paymentVC == nil, let projectId = project?.id {
                    paymentVC = PaymentMethodListViewController(
                        for: projectId,
                        nil
                    )
                }
            }
    }
}
```

## 📦 SDK Dependencies

The app integrates these SDK modules via Swift Package Manager:

- **SnabbleCore** - Core business logic and models
- **SnabbleUI** - Pre-built UI components
- **SnabbleScanAndGo** - Complete shopping flow (`ShopperView`)
- **SnabbleAssetProviding** - Asset provider protocol
- **SnabbleComponents** - Reusable UI components

## 🔧 Troubleshooting

### Build Errors

**Problem:** "Cannot find type 'Shopper' in scope"
**Solution:** Add `SnabbleScanAndGo` package dependency

**Problem:** "Module compiled with Swift 5.x cannot be imported"
**Solution:** Set Swift Language Version to Swift 6 in Build Settings

**Problem:** Concurrency errors
**Solution:** Enable "Strict Concurrency Checking: Complete"

### Package Dependencies

If local package is not found:
1. File > Packages > Reset Package Caches
2. Verify package path in Project Settings
3. Clean and rebuild (⌘⇧K then ⌘B)

## 🆚 UIKit vs SwiftUI Comparison

| Feature | UIKit (Snabble) | SwiftUI (SwiftySnabble) |
|---------|-----------------|-------------------------|
| App Lifecycle | AppDelegate | SwiftUI App |
| Navigation | UINavigationController | NavigationStack + Router |
| State | ViewControllers | @Observable |
| Tab Bar | UITabBarController | TabView |
| Scanner | ScannerViewController | ShopperView |
| Concurrency | Callbacks | async/await |
| Previews | ❌ | ✅ |
| Code Lines | ~2000 | ~1200 |
| Swift Version | 5.x | 6.2 |

## 📄 License

Copyright © 2026 snabble GmbH. All rights reserved.

---

## 🤝 Contributing

When adding new features:

1. Follow the feature-based directory structure
2. Use `@Observable` for state management
3. Keep navigation logic in `AppRouter`
4. Add localization keys to `Localizable.xcstrings`
5. Create Xcode Previews for all views
6. Use `#Preview` macro for quick iteration
7. Follow Swift 6 concurrency best practices

## 📚 Further Reading

- [Snabble SDK Documentation](https://docs.snabble.io/)
- [Swift 6 Migration Guide](../../documentation/Swift-6-Migration-Plan-EN.md)
- [SwiftUI Navigation Guide](https://developer.apple.com/documentation/swiftui/navigation)
- [@Observable Documentation](https://developer.apple.com/documentation/observation/observable())
