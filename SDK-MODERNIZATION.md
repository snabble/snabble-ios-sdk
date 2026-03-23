# SnabbleSDK Modernization Guide
## Swift 6.2 & SwiftUI Migration

**Status:** ✅ Phase 1 Complete - Swift 6 Migration Finished  
**Current Version:** 1.8.0 (integrated in teo-ios)  
**Target:** Swift 6.2 + SwiftUI-first API  
**Last Updated:** 2026-03-22

---

## Executive Summary

This document outlines the modernization strategy for transforming SnabbleSDK from a UIKit-based framework to a Swift 6.2-compliant, SwiftUI-first SDK while maintaining backward compatibility during the transition period.

### Current State Analysis

✅ **Already Modernized:**
- **PaymentMethods** - Full SwiftUI + `@Observable` models (see `PaymentMethods/MIGRATION-SUMMARY.md`)
- **ScanAndGo** - Complete SwiftUI scanner with `Shopper` model
- **ShoppingCart** - SwiftUI views available
- **Coupons** - SwiftUI implementation exists
- **DynamicView** - Widget system in SwiftUI
- **ShopFinder** - SwiftUI shop views

🔄 **Needs Migration:**
- Legacy Scanner (Pulley-based `ScannerViewController`)
- Checkout flow ViewControllers
- Receipt detail views
- Some payment method edit screens (third-party SDKs)

---

## Architecture Philosophy

### Before: UIKit-Centric
```
┌─────────────────────────────┐
│  UIViewController           │
│  ├─ Business Logic (inline) │
│  ├─ UI Code                 │
│  └─ Delegates               │
└─────────────────────────────┘
```

### After: SwiftUI-First with Shared Models
```
┌──────────────────────────────────┐
│  @Observable Business Model      │
│  @MainActor                      │
│  ├─ State Management             │
│  ├─ Business Logic               │
│  └─ async/await Operations       │
└───────────┬──────────────────────┘
            │
    ┌───────┴────────┐
    │                │
┌───▼────────┐  ┌───▼──────────┐
│  SwiftUI   │  │  UIKit       │
│  (Primary) │  │  (Deprecated)│
└────────────┘  └──────────────┘
```

---

## Module Status

### ✅ Core (Fully Modern)
**Location:** `Core/Sources/`

- ✅ Swift 6 concurrency compliant
- ✅ `@MainActor` isolation where needed
- ✅ async/await throughout
- ✅ No UIKit dependencies
- ✅ `@Observable` for state (not Combine)

**Key Models:**
- `ShoppingCart` - Cart management
- `Snabble` - SDK entry point
- `Project`, `Shop` - Metadata models
- `CheckoutProcess` - Checkout logic

### ✅ ScanAndGo (Modern SwiftUI)
**Location:** `ScanAndGo/Shopping/`

**Status:** ✅ **This is the reference implementation!**

**Architecture:**
```swift
@Observable
@MainActor
public final class Shopper {
    public var barcodeManager: BarcodeManager
    public var cartModel: ShoppingCartViewModel
    public var paymentManager: PaymentMethodManager
    // Business logic only
}

public struct ShopperView: View {
    @Environment(Shopper.self) private var model
    // Pure SwiftUI, no UIKit
}
```

**Features:**
- ✅ Barcode scanning with camera
- ✅ Manual code entry
- ✅ Shopping cart integration
- ✅ Payment method selection
- ✅ Checkout flow
- ✅ Error handling with native alerts
- ✅ Search functionality

**Usage:**
```swift
import SnabbleScanAndGo

let shopper = Shopper(shop: shop)

ShopperView()
    .environment(shopper)
```

### 🔄 UI Module (Mixed - Needs Cleanup)
**Location:** `UI/Sources/`

#### ✅ Modern SwiftUI Components

**PaymentMethods/** ✅
- `PaymentMethodListView` - Main list
- `PaymentEditView` - Edit wrapper
- `SepaDataEditView` - Pure SwiftUI SEPA
- `TeleCashCreditCardDisplayView` - Pure SwiftUI
- `PaymentMethodListManager` - `@Observable` model

**ShoppingCart/** ✅
- `ShoppingCartView`
- `ShoppingCartItemsView`
- `CartItemView`

**Coupons/** ✅
- `CouponsView`
- `CouponCardView`

**DynamicView/** ✅
- Widget system for settings/dashboard
- All SwiftUI-based

**Checkout/** ✅
- `CheckoutStepView`
- `CheckoutInformationView`
- `CheckoutRatingView`

#### 🔴 Deprecated UIKit (To Be Removed)

**Scanner/** 🔴
```swift
@available(*, deprecated, message: "Use ShopperView from SnabbleScanAndGo instead")
public final class ScannerViewController: PulleyViewController { }

@available(*, deprecated, message: "Use ShopperView from SnabbleScanAndGo instead")
public final class ScanningViewController: UIViewController { }

@available(*, deprecated, message: "Use Shopper.barcodeManager instead")
public final class BarcodeEntryViewController: UIViewController { }
```

**Reason for deprecation:**
- Depends on third-party Pulley (drawer library)
- Complex UIKit hierarchy
- Duplicate functionality of ScanAndGo
- Not Swift 6 concurrency compliant

**Migration Path:**
```swift
// Before (UIKit)
let scanner = ScannerViewController(cart, shop, detector)
scanner.scannerDelegate = self
scanner.shoppingCartDelegate = self
navigationController?.pushViewController(scanner, animated: true)

// After (SwiftUI)
let shopper = Shopper(shop: shop)

NavigationStack {
    ShopperView()
        .environment(shopper)
}
```

**Checkout/** 🔴
```swift
@available(*, deprecated, message: "Use CheckoutView from SnabbleScanAndGo instead")
public final class InFlightCheckoutContinuationViewController: UIViewController { }
```

**Receipts/** 🔴
```swift
@available(*, deprecated, message: "Use ReceiptDetailView (SwiftUI) instead")
public final class ReceiptsDetailViewController: UIViewController { }
```

**Payment/** ⚠️ (Partially deprecated)
- Some payment edit screens must stay UIKit (third-party SDKs)
- Wrapped via `ContainerView` for SwiftUI access

---

## Migration Strategy

### Phase 1: Deprecation Warnings (Current)

**Timeline:** SDK v1.8.x (Q2 2026)

**Actions:**
1. ✅ Mark all UIKit ViewControllers as `@available(*, deprecated)`
2. ✅ Add migration messages pointing to SwiftUI alternatives
3. ✅ Create this guide
4. ✅ Update README with SwiftUI examples first

**Example Deprecation:**
```swift
@available(*, deprecated, renamed: "ShopperView", message: """
    ScannerViewController is deprecated. Use ShopperView from SnabbleScanAndGo instead:
    
    let shopper = Shopper(shop: shop)
    ShopperView().environment(shopper)
    
    See SDK-MODERNIZATION.md for migration guide.
    """)
public final class ScannerViewController: PulleyViewController {
    // Legacy implementation
}
```

### Phase 2: Dual API Period (6-12 months)

**Timeline:** SDK v1.9.x - v1.11.x (Q3 2026 - Q1 2027)

**Support:**
- ✅ Both UIKit and SwiftUI APIs available
- ✅ Apps can migrate gradually
- ✅ Bug fixes for both implementations
- ⚠️ New features only in SwiftUI

**Communication:**
- Release notes mention deprecation
- Migration guide published
- Sample app updated to SwiftUI

### Phase 3: UIKit Removal (Breaking Change)

**Timeline:** SDK v2.0 (Q2 2027)

**Actions:**
1. 🔨 Delete deprecated UIKit ViewControllers
2. 🔨 Remove Pulley dependency
3. 🔨 Remove Combine (replaced by async/await)
4. 🔨 Clean up `#if canImport(UIKit)` bridges

**Remaining UIKit:**
- Only third-party payment SDK wrappers
- Internal utilities (if needed)
- Everything wrapped via `ContainerView`

---

## Swift 6.2 Compliance Checklist

### ✅ Strict Concurrency
```swift
// ✅ DO: Proper isolation
@MainActor
@Observable
class ViewModel {
    var state: State = .idle
    
    func updateState() async {
        // MainActor-isolated
    }
}

// ❌ DON'T: nonisolated(unsafe)
class LegacyModel {
    nonisolated(unsafe) var data: [Item] = []  // Swift 6 warning
}
```

### ✅ Observable Macro
```swift
// ✅ DO: Use @Observable (Swift 5.9+)
@Observable
class Model {
    var count: Int = 0
}

struct MyView: View {
    @State private var model = Model()
    // Auto-tracking, no manual objectWillChange
}

// ❌ DON'T: Use ObservableObject (old)
class OldModel: ObservableObject {
    @Published var count: Int = 0
}
```

### ✅ Async/Await over Combine
```swift
// ✅ DO: async/await
func loadData() async throws -> Data {
    try await urlSession.data(from: url).0
}

// ❌ DON'T: Combine (unless interop needed)
func loadData() -> AnyPublisher<Data, Error> {
    urlSession.dataTaskPublisher(for: url)
        .map(\.data)
        .eraseToAnyPublisher()
}
```

### ✅ Sendable Conformance
```swift
// ✅ DO: Make data types Sendable
struct ScanResult: Sendable {
    let code: String
    let format: ScanFormat
}

// ⚠️ CAREFUL: Reference types
@MainActor
class ViewModel: @unchecked Sendable {
    // Only if truly thread-safe via MainActor
}
```

---

## API Evolution

### Scanner API

#### Legacy (Deprecated)
```swift
// UIKit - DEPRECATED
let scanner = ScannerViewController(cart, shop, detector)
scanner.scannerDelegate = self
scanner.shoppingCartDelegate = self
navigationController?.pushViewController(scanner, animated: true)
```

#### Modern (Recommended)
```swift
// SwiftUI - RECOMMENDED
import SnabbleScanAndGo

@State private var shopper: Shopper

init(shop: Shop) {
    self.shopper = Shopper(shop: shop)
}

var body: some View {
    NavigationStack {
        ShopperView()
            .environment(shopper)
    }
}
```

### Payment Methods API

#### Legacy (Still works)
```swift
// UIKit
let listVC = PaymentMethodListViewController(for: projectId, analyticsDelegate)
navigationController?.pushViewController(listVC, animated: true)
```

#### Modern (Preferred)
```swift
// SwiftUI
NavigationStack {
    PaymentMethodListView(
        projectId: projectId,
        analyticsDelegate: analyticsDelegate
    )
}
```

### Checkout API

#### Legacy (Deprecated)
```swift
// UIKit - DEPRECATED
let checkoutVC = InFlightCheckoutContinuationViewController(...)
present(checkoutVC, animated: true)
```

#### Modern (To be implemented)
```swift
// SwiftUI - Coming soon
CheckoutView(shopper: shopper)
    .environment(shopper)
```

---

## Testing Strategy

### Unit Tests
```swift
// Business logic tests (UI-agnostic)
@Test func testShopperAddItem() async {
    let shopper = Shopper(shop: testShop)
    await shopper.addScannedItem(testItem)
    #expect(shopper.cartModel.items.count == 1)
}
```

### SwiftUI Previews
```swift
#Preview("Shopping") {
    let shopper = Shopper(shop: Shop.preview)
    
    ShopperView()
        .environment(shopper)
}
```

### Snapshot Testing
```swift
// Use swift-snapshot-testing
func testShopperView() {
    let shopper = Shopper(shop: testShop)
    let view = ShopperView().environment(shopper)
    
    assertSnapshot(of: view, as: .image)
}
```

---

## Dependencies Cleanup

### Remove in v2.0
- ❌ **Pulley** (drawer UI library) - Replace with native SwiftUI
- ❌ **Combine** (where possible) - Replace with async/await
- ⚠️ **RxSwift** (if any) - Already removed?

### Keep
- ✅ **SwiftUI** - Primary UI framework
- ✅ **Observation** - Swift 5.9+ macro
- ✅ **Swift Concurrency** - async/await, actors, @MainActor

### Third-Party Payment SDKs (Keep but wrap)
- Payone SDK (UIKit-based)
- Datatrans SDK (UIKit-based)
- TeleCash SDK (UIKit-based)
- Wrapped via `ContainerView` for SwiftUI access

---

## File Organization

### Recommended Structure
```
snabble-ios-sdk/
├── Core/                      # ✅ Pure Swift, no UI
│   ├── Models/
│   ├── Networking/
│   └── Business Logic/
│
├── ScanAndGo/                 # ✅ SwiftUI Scanner (Reference)
│   ├── Models/
│   │   ├── Shopper.swift (@Observable)
│   │   └── BarcodeManager.swift
│   └── Views/
│       ├── ShopperView.swift
│       └── BarcodeScannerView.swift
│
├── UI/                        # 🔄 Mixed (cleaning up)
│   ├── PaymentMethods/        # ✅ Modern
│   │   ├── Models/
│   │   │   └── PaymentMethodListManager.swift (@Observable)
│   │   ├── SwiftUI/
│   │   │   ├── List/
│   │   │   ├── Edit/
│   │   │   └── Pure/
│   │   └── UIKit/             # Deprecated
│   │
│   ├── ShoppingCart/          # ✅ Modern
│   │   └── Views/
│   │
│   ├── Checkout/              # ✅ Modern views, 🔴 deprecated VCs
│   │   ├── CheckoutStepView.swift
│   │   └── [Deprecated VCs]
│   │
│   ├── Scanner/               # 🔴 TO DELETE in v2.0
│   │   └── [Legacy UIKit scanners]
│   │
│   └── Receipts/              # 🔄 Needs SwiftUI migration
│
├── Components/                # ✅ Reusable SwiftUI
│   └── SwiftUI/
│       ├── Buttons/
│       ├── Dialogs/
│       └── Web/
│
├── AssetProviding/            # ✅ Resources
│   ├── Assets.xcassets
│   └── Localizations
│
└── Documentation/
    ├── SDK-MODERNIZATION.md   # 👈 This file
    ├── PaymentMethods/MIGRATION-SUMMARY.md
    └── README.md
```

---

## Communication Plan

### For App Developers

**Deprecation Warnings (v1.8.x):**
```
⚠️ 'ScannerViewController' is deprecated: Use ShopperView from SnabbleScanAndGo instead

let shopper = Shopper(shop: shop)
ShopperView().environment(shopper)

See SDK-MODERNIZATION.md for migration guide.
```

**Release Notes Template:**
```markdown
## v1.8.0 - SwiftUI Modernization

### Deprecated APIs
- `ScannerViewController` → Use `ShopperView` (SnabbleScanAndGo)
- `ScanningViewController` → Use `ShopperView` (SnabbleScanAndGo)
- `BarcodeEntryViewController` → Use `Shopper.barcodeManager`

### Migration Guide
See `SDK-MODERNIZATION.md` for complete migration instructions.

### Timeline
- v1.8.x - v1.11.x: Both APIs supported
- v2.0 (Q2 2027): UIKit ViewControllers removed

### Benefits of Migration
- ✅ Swift 6.2 strict concurrency
- ✅ Native SwiftUI animations
- ✅ Smaller binary size (no Pulley)
- ✅ Better performance
- ✅ Future-proof API
```

---

## FAQ

### Q: Do I need to migrate immediately?
**A:** No. Both APIs will be supported for 6-12 months. Plan migration when convenient.

### Q: What about third-party payment SDKs?
**A:** They remain UIKit-based but are wrapped via `ContainerView`. No action needed.

### Q: Will there be breaking changes?
**A:** Not until v2.0. All v1.x releases maintain backward compatibility.

### Q: Can I use SwiftUI and UIKit together?
**A:** Yes! You can use `ShopperView` (SwiftUI) while keeping other parts UIKit.

### Q: What iOS version is required?
**A:** iOS 17.0+ for `@Observable` macro. Consider iOS 18.0+ for latest SwiftUI features.

### Q: How do I test the new APIs?
**A:** See the `Example/` app which demonstrates both old and new patterns.

---

## Next Steps

### For SDK Maintainers

1. ✅ Add `@available(*, deprecated)` to all UIKit ViewControllers
2. ⬜ Create SwiftUI receipt detail view
3. ⬜ Create SwiftUI checkout continuation view
4. ⬜ Update README with SwiftUI examples first
5. ⬜ Add SwiftUI examples to Example app
6. ⬜ Set up CI to test both APIs
7. ⬜ Create v2.0 milestone for UIKit removal

### For App Developers

1. ⬜ Read this guide
2. ⬜ Identify usage of deprecated APIs
3. ⬜ Plan migration timeline
4. ⬜ Start with Scanner (biggest win)
5. ⬜ Migrate payment screens (if needed)
6. ⬜ Update to v2.0 when ready

---

## Success Metrics

**Code Reduction:**
- PaymentMethods: -40% UIKit code after extraction
- Scanner: Expected -60% after Pulley removal

**Developer Experience:**
- Fewer lines of code to integrate scanner
- Native SwiftUI navigation
- Better Xcode previews

**Performance:**
- Smaller binary size (no Pulley dependency)
- Better animation performance (SwiftUI)
- Reduced memory usage (no duplicate scanner implementations)

---

## References

- [PaymentMethods Migration Summary](UI/Sources/PaymentMethods/MIGRATION-SUMMARY.md)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Swift 6 Migration Guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

**Last Updated:** 2026-03-21  
**SDK Version:** 1.8.0-beta  
**Author:** SDK Team
