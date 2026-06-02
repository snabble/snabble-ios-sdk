# Changelog

## [1.0.0] - 2026-06-02

Version 1.0.0 requires Swift 6.2 and is not backward compatible with 0.x releases.

### Breaking Changes

**Language and toolchain**
- Swift 6.2 required (was: 5.10)
- iOS 17.0 minimum deployment target (was: iOS 15.0)
- Xcode 16.4 or later required

**Module changes**
- `SnabbleUI` removed. The UIKit-based `ScannerViewController` is replaced by `ShopperView` from `SnabbleScanAndGo`.
- `SnabblePay` moved to a separate package. Import `SnabblePayment` for payment processing.
- `SnabbleAssetProviding` is now a separate module. Update imports accordingly.

**Observable pattern**
- All view models migrated from `ObservableObject` to `@Observable` (Swift Observation framework).
- Replace `@StateObject` with `@State`, `@ObservedObject` with plain properties.
- Remove `@Published` from observed properties.

**Main entry point**

```swift
// 0.x
let scannerVC = ScannerViewController(cart: cart)

// 1.0.0
import SnabbleScanAndGo
let shopper = Shopper(shop: shop)
ShopperView(model: shopper)
```

Apply `.shopperActions()` once at the root of your view hierarchy to receive toasts, dialogs, and alerts:

```swift
RootView()
    .shopperActions()
```

### Added

- `SnabbleScanAndGo` — complete SwiftUI Scan & Go flow (`Shopper`, `ShopperView`, `BarcodeManager`)
- `SnabbleTheme` — dedicated module for theming and asset management
- `SnabbleCart`, `SnabbleReceipts`, `SnabbleShops`, `SnabbleCoupons`, `SnabbleTeaser`, `SnabbleOnboarding` — extracted as independent modules
- `Shopper.cartUpdateDelay` — configurable debounce for cart backend recalculation

### Removed

- `ScannerViewController` (UIKit) — use `ShopperView` from `SnabbleScanAndGo`
- `DynamicView` widget system
- `SnabblePay` (standalone package, not part of this SDK)

### Migration

See `documentation/Swift-6-Migration.md` for the complete migration reference.

---

## [0.73.4] and earlier

See git history for changes prior to 1.0.0.
