# Snabble iOS SDK – Release Report: 0.73.3 → 1.0.0

**Branch:** `swift6-again` → `main`  
**Date:** May 19, 2026  
**Commits:** 154 commits since merge point  
**Scope:** 658 changed files, +16,829 / −21,351 lines

---

## 1. Core Changes

### Swift 6.3 Migration (Breaking Change)

The most significant change in this release is the complete migration to Swift 6.3 with strict concurrency checking enabled:

- `Package.swift` updated from `swift-tools-version: 5.10` to **6.3**
- 25 `ObservableObject` classes migrated to the **`@Observable` macro** (`@Published` removed)
- `@MainActor` isolation enforced for all UI-facing classes
- `nonisolated` callbacks for framework delegates (AVFoundation, CLLocationManager)
- `AssetManager` migrated from `ReadWriteLock + @unchecked Sendable` to **actor isolation**
- `SnabblePay` removed from the SDK (continues as a separate package)
- `@dynamicMemberLookup` removed

#### Migration Guide for SDK Consumers

```swift
// Before (0.x)
@StateObject var cart = ShoppingCartViewModel(...)
@ObservedObject var cart: ShoppingCartViewModel

// After (1.0+)
@State var cart = ShoppingCartViewModel(...)
var cart: ShoppingCartViewModel           // passed from parent
@Environment(ShoppingCartViewModel.self)  // via environment
```

---

### New Module Architecture (Breaking Change)

The previous flat structure has been replaced by a **5-layer architecture** without circular dependencies:

| Layer | Modules |
|-------|---------|
| 1 – Foundation | `SnabbleCore`, `SnabbleNetwork`, `SnabbleAssetProviding` |
| 2 – UI Primitives | `SnabbleComponents`, `SnabbleTheme` *(new)* |
| 3 – Domain Features | `SnabbleShops` *(new)*, `SnabbleCart` *(new)*, `SnabbleUser`, `SnabbleReceipts` *(new)* |
| 4 – Payment | `SnabblePayment` *(new, extracted from `SnabbleUI`)* |
| 5 – Complete Flows | `SnabbleScanAndGo`, `SnabblePhoneAuth`, `SnabbleCoupons` *(new)*, `SnabbleOnboarding`, `SnabbleTeaser` *(new)* |

The previous `SnabbleUI` module has been dissolved: 55 files from `UI/Sources` were deleted and their functionality moved into the respective new modules. The `DynamicView` widget system (14 files) has been removed.

---

### SnabbleScanAndGo – New Primary Entry Point

The recommended way to integrate the SDK is now the pure SwiftUI API:

```swift
// 0.x (legacy) – UIKit-based ScannerViewController

// 1.0+ (new)
@State private var shopper = Shopper(shop: shop)
ShopperView(model: shopper)
    .onCheckoutCompleted { receipt in ... }
```

---

### Payment Module Modernized

New SwiftUI views introduced for payment methods:

- `PaymentMethodListView`, `PaymentMethodAddSheet`
- `PaymentEditView`, `ProjectPaymentSelectionView`
- `SepaDataEditView`, `TeleCashCreditCardDisplayView`

UIKit views remain available for existing use cases.

---

### New SwiftUI Sample App (SwiftySnabble)

The legacy UIKit-based sample app (`Example/Snabble/`) has been replaced by a full SwiftUI app (`Example/SwiftySnabble/`), serving as the reference implementation for SDK consumers.

---

## 2. Known Issues (1.x)

| File | Issue |
|------|-------|
| `Core/Sources/Payment/Giropay.swift` | TODO: Remove `ipAddress`/`fingerprint`; multi-account logic unresolved |

---

## 3. Status

All critical and medium-priority issues have been resolved. The remaining TODOs are tracked as **Known Issues 1.x** and do not block the merge.
