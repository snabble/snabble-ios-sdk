# Snabble iOS SDK - Swift 6.2 Migration & Technical Debt Plan

**Goal:** Migration to Swift 6.2 with Approachable Concurrency, @Observable, and SwiftUI modernization

---

## Executive Summary

Migration of the Snabble iOS SDK from Swift 5.10 to Swift 6.2 with:
- Approachable Concurrency (Default MainActor Isolation)
- ObservableObject to @Observable migration (25+ classes)
- UIKit to SwiftUI where appropriate (Example App, simple views)
- Technical debt cleanup from 2020-2024

**Estimated Total Effort:** 7-10 weeks (with Agent Skills support) / 14-16 weeks (manual)

---

## Current State

### Package Configuration
- **Swift Tools Version:** 5.10 (needs update to 6.2)
- **iOS Target:** 17.0+ (remains unchanged - Swift 6.2 is independent of iOS target)
- **Modules:** 10 (Network, Core, UI, Components, AssetProviding, Pay, User, PhoneAuth, Datatrans, ScanAndGo)

### Compatibility Strategy
- **Incremental migration** with soft deprecations
- Continue supporting existing SDK consumers
- Breaking changes only where unavoidable (e.g., ObservableObject → @Observable)

### Technical Debt Inventory

| Category | Count | Status |
|----------|-------|--------|
| ObservableObject Classes | 25 | Migration required |
| @Published Properties | 69 | Remove after migration |
| @ObservedObject Usages | 40+ | Convert to @Environment/@State |
| UIKit ViewControllers | 64 | Partially migrate |
| Concurrency Annotations (Core) | 0 | Add |
| Test Coverage (UI Module) | 0% | Add tests |

---

## Phase 1: Foundation Setup (Week 1-2)

### 1.1 Package.swift Update
**File:** `Package.swift`

```swift
// swift-tools-version: 6.2
platforms: [.iOS(.v17)]  // Keep iOS 17 for compatibility
```

Add Swift settings for each target:
```swift
swiftSettings: [
    .swiftLanguageMode(.v6)
]
```

**Note:** Swift 6.2 language features are independent of iOS deployment target. Approachable Concurrency, @Observable, and all other Swift 6.2 features work with iOS 17.0.

### 1.2 Verify Dependencies
- GRDB.swift 6.29.3+ - Swift 6 compatible
- KeychainAccess 4.2.2+ - verify
- Datatrans 3.7.3+ - verify
- Pulley 2.9.2 - may need fork for Swift 6

### 1.3 Validation
```bash
swift package resolve
xcodebuild -scheme Snabble-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build
```

---

## Phase 2: Network & Core Concurrency (Week 2-4)

### 2.1 SnabbleNetwork Module
- NetworkManager async/await enhancement
- @Sendable for completion handlers
- Authenticator thread safety

### 2.2 SnabbleCore Module
Critical classes:
- `Snabble.shared` - Singleton isolation
- `ShoppingCart` - MainActor for UI, @concurrent for DB
- `ProductDatabase` - GRDB integration with actor isolation
- `CheckInManager` - CLLocationManager delegates

---

## Phase 3: @Observable Migration (Week 4-9)

### Tier 1 - Simple Classes (10 classes, ~2 weeks)

| Class | File | Effort |
|-------|------|--------|
| RatingModel | UI/Sources/Checkout/CheckoutRatingView.swift | 1h |
| CouponViewModel | UI/Sources/Coupons/CouponViewModel.swift | 1h |
| OnboardingViewModel | UI/Sources/Onboarding/Model/OnboardingViewModel.swift | 2h |
| ShoppingCartViewModel | UI/Sources/ShoppingCart/Models/ShoppingCartViewModel.swift | 4h |
| PaymentMethodManager | UI/Sources/Payment/PaymentMethodManager.swift | 3h |
| ActionManager | ScanAndGo/Shopping/Models/ActionState.swift | 1h |
| BarcodeManager | ScanAndGo/Shopping/Models/BarcodeManager.swift | 2h |
| Shopper | ScanAndGo/Shopping/Models/Shopper.swift | 4h |
| StartShoppingViewModel | UI/Sources/DynamicView/WidgetStartShoppingView.swift | 1h |
| CheckoutModel | UI/Sources/Checkout/CheckoutStepsViewController.swift | 2h |

**Migration Pattern:**
```swift
// BEFORE
class CouponViewModel: ObservableObject {
    @Published var image: UIImage?
}

// AFTER
@Observable
class CouponViewModel {
    var image: UIImage?
}
```

### Tier 2 - Complex Combine Validation (4 classes, ~2 weeks)

| Class | File | Complexity |
|-------|------|------------|
| SepaDataModel | UI/Sources/PaymentMethods/Models/SepaDataModel.swift | PCI-critical |
| LoginViewModel | UI/Sources/Login/LoginViewModel.swift | Inheritance base |
| PaymentSubjectViewModel | UI/Sources/PaymentMethods/Models/PaymentSubjectViewModel.swift | Debounce |
| SepaAcceptModel | UI/Sources/PaymentMethods/Models/SepaAcceptModel.swift | SEPA Mandate |

**Hybrid Pattern for Combine:**
```swift
@Observable
class SepaDataModel {
    private let ibanSubject = CurrentValueSubject<String, Never>("")

    var ibanNumber: String = "" {
        didSet { ibanSubject.send(ibanNumber) }
    }

    // Existing Combine publishers remain
}
```

### Tier 3 - Special Cases (7 classes, ~2 weeks)

| Class | Problem | Solution |
|-------|---------|----------|
| DynamicViewModel | NSObject + Decodable | nonisolated(unsafe) for properties |
| DeveloperModeViewModel | NSObject | Direct migration |
| LocationPermissionViewModel | CLLocationManager | nonisolated delegates |
| InvoiceLoginModel | Inherits from LoginViewModel | Swift 6 @Observable inheritance |
| InvoiceLoginProcessor | ObservableObject | Standard migration |
| BaseCheckViewModel | Security-critical | Careful migration |
| CartItemModel | Open class hierarchy | Migrate base first |

### View Updates

```swift
// BEFORE
@ObservedObject var viewModel: CouponViewModel
@StateObject var viewModel: CouponViewModel
@EnvironmentObject var viewModel: CouponViewModel

// AFTER
@Environment(CouponViewModel.self) var viewModel  // preferred
@State var viewModel: CouponViewModel              // alternative
```

---

## Phase 4: UIKit to SwiftUI Migration (Week 9-11)

### Migrate (Easy)

| Component | Effort | Priority |
|-----------|--------|----------|
| ReceiptsDetailViewController | 4h | High |
| CouponsViewController | 2h | High |
| SelectionSheetController | 3h | Medium |
| AlertView | 2h | Medium |
| BarcodeEntryViewController | 3h | Low |

### DO NOT Migrate (Security/Hardware)

- Payment Methods VCs (8) - PCI Compliance
- Payment Processing VCs (5) - Security-critical
- ScanningViewController - AVFoundation
- ScannerViewController - Pulley Drawer

---

## Phase 5: Example App Modernization (Week 11-13)

### 5.1 From UIKit AppDelegate to SwiftUI App

**File:** `Example/Snabble/SnabbleSampleApp.swift` (new)

```swift
@main
struct SnabbleSampleApp: App {
    @State private var appState = SnabbleAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

@Observable
@MainActor
class SnabbleAppState {
    var isLoaded = false
    var project: Project?
    // ...
}
```

### 5.2 TabView Navigation

```swift
struct ContentView: View {
    @Environment(SnabbleAppState.self) var state

    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Home", systemImage: "house") }
            ShopsView().tabItem { Label("Shops", systemImage: "building.2") }
            ScannerView().tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
            ReceiptsView().tabItem { Label("Receipts", systemImage: "scroll") }
            AccountView().tabItem { Label("Account", systemImage: "person") }
        }
    }
}
```

### 5.3 Files to Delete
- `AppDelegate.swift` (after migration)
- `LoadingViewController.swift`
- Other UIKit-specific helpers

---

## Phase 6: Cleanup & Documentation (Week 13-16)

### 6.1 Remove Legacy Code
- All `objectWillChange.send()` calls
- Unused Combine imports
- `@Published` from @Observable classes
- Deprecated property wrappers

### 6.2 Update CI/CD
- GitHub Actions to Xcode 17+ / macOS 16
- Simulator to iOS 18.5+
- Swift 6.2 strict mode validation

### 6.3 Documentation
- Update CLAUDE.md with final patterns
- Update README.md with Swift 6.2 requirements
- Migration guide for SDK consumers

---

## Time Estimates

| Phase | Without Agent | With Agent Skills | Savings |
|-------|---------------|-------------------|---------|
| Phase 1: Foundation | 1 week | 2-3 days | 50% |
| Phase 2: Concurrency | 2 weeks | 1 week | 50% |
| Phase 3: @Observable | 5 weeks | 2-3 weeks | 50% |
| Phase 4: UIKit→SwiftUI | 2 weeks | 1 week | 50% |
| Phase 5: Example App | 2 weeks | 1 week | 50% |
| Phase 6: Cleanup | 1-2 weeks | 1 week | 30% |
| **Total** | **14-16 weeks** | **7-10 weeks** | **~50%** |

### Relevant Agent Skills
- `swift-concurrency-expert` - Concurrency review & migration
- `swiftui-view-refactor` - SwiftUI view refactoring
- `swiftui-ui-patterns` - SwiftUI best practices
- `swiftui-performance-audit` - Performance optimization

---

## Risks & Mitigations

| Risk | Probability | Mitigation |
|------|-------------|------------|
| Dependencies not Swift 6 compatible | Medium | Early audit in Phase 1 |
| PCI Compliance with Payment | Low | No changes to validation logic |
| GRDB Actor Isolation | Medium | @concurrent for DB operations |
| Breaking Changes for SDK Consumers | High | See compatibility strategy |

---

## Compatibility Strategy for SDK Consumers

### Unavoidable Breaking Changes
Migration from `ObservableObject` to `@Observable` is a **breaking change** for consumers:

```swift
// Consumer Code BEFORE
@ObservedObject var shopper: Shopper

// Consumer Code AFTER
@State var shopper: Shopper
// or
@Environment(Shopper.self) var shopper
```

### Recommended Strategy: Soft Deprecation + Major Version

1. **Version 0.74.x** - Add deprecation warnings
   - `@available(*, deprecated, message: "Will be replaced with @Observable in 1.0")`
   - Document upcoming changes

2. **Version 1.0.0** - Swift 6.2 Migration
   - All ObservableObject → @Observable
   - Clear migration guide for consumers
   - Changelog with all breaking changes

### What Stays Compatible
- All public API signatures (method names, parameters)
- Existing protocols (Shopper, ShopperView entry points)
- Data models (CartItem, Product, Shop, etc.)
- Configuration pattern (Snabble.setup)

### What Changes
- Property wrappers in views (@ObservedObject → @State/@Environment)
- ViewModel initialization pattern
- Combine Publishers → @Observable properties

---

## Verification

### After Each Phase
```bash
# Check build
xcodebuild -scheme Snabble-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build

# Run tests
xcodebuild -scheme Snabble-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' test

# SwiftLint
swiftlint --strict --quiet
```

### End-to-End Test
1. Launch Example App
2. Test shop check-in
3. Scan product
4. Verify shopping cart
5. Complete payment flow
6. View receipt

---

## Critical Files

**Package Configuration:**
- `Package.swift`

**Core ViewModels (Priority 1):**
- `UI/Sources/ShoppingCart/Models/ShoppingCartViewModel.swift`
- `ScanAndGo/Shopping/Models/Shopper.swift`
- `UI/Sources/Payment/PaymentMethodManager.swift`

**Security-Critical (Caution):**
- `UI/Sources/PaymentMethods/Models/SepaDataModel.swift`
- `UI/Sources/Login/LoginViewModel.swift`

**Example App:**
- `Example/Snabble/AppDelegate.swift`

---

## Next Steps

1. ~~Plan review and approval~~ ✅
2. Create branch for migration (`feature/swift-6.2-migration`)
3. Start Phase 1: Package.swift update
4. Conduct dependencies audit
5. Work through phases iteratively
