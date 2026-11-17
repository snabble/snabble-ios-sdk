# Changelog

## [1.3.0] - Unreleased

### Toolchain

- Building the SDK now requires **Xcode 27.1 or later** (iOS 27.1 SDK). The deployment target stays iOS 17.0.

### Added

- `ShopperView` shows the cart beside the scanner when the available space is wider than tall (iPad, Stage Manager, resizable windows, iPhone in landscape). On iOS 27.1+ in regular width a split `ArrangementView` divides scanner and cart at the fold of a partially open iPhone Duo.
- `ShopsListView` and `ShopsDetailView` as building blocks for a custom `NavigationSplitView`.
- Multi-window support: each `ActionModifier` gets its own action stream and ignores actions while its scene is in the background.

### Changed

- `ShopsView` uses a `NavigationSplitView` instead of the deprecated `NavigationView`. Its public API is unchanged, but it must not be nested in another navigation container.
- The camera preview keeps the correct rotation when a window is resized without a device rotation.
- `UIScreen.main` is no longer used for layout in the scanner and the pull-over drawer.
- `CameraZoomWheel` updated to 2.1.0.

### Fixed

- `Shopper` and `PaymentMethodManager` use the shopper's own project instead of the global `SnabbleCI.project`.
- Brands with a single visible project skip the brand level in the payment method list.
- The pull-over height and the payment state are restored after returning from a pushed payment screen.
- A failing notification permission request is treated as "not authorized" instead of propagating the error.

### Removed

- `UIApplication.topViewController` / `topNavigationController` and unused `UITabBarController` extensions.

## [1.2.1] - 2026-08-26

### Fixed

- Prevent duplicate anonymous `AppUser` creation on first launch (#494).
- Disambiguate `externalBilling` payment methods by `originType` (#493).

## [1.2.0] - 2026-07-29

### Breaking Changes

- Combine replaced by `AsyncStream` across all SDK modules (#489). `actionPublisher` / `barcodePublisher` are replaced by `actionStream` / `barcodeStream`:

```swift
// 1.1.x
viewModel.actionPublisher.sink { action in … }

// 1.2.0
for await action in viewModel.actionStream { … }
```

## [1.1.3] - 2026-07-28

### Added

- `User.hasValidPhoneNumber` (#483).

### Fixed

- Gateway certificate validation now matches the Android SDK (#484).
- `ScannerCartView` layout cycling and drawer stability (#481, #482).

## [1.1.2] - 2026-07-21

### Fixed

- Barcode scanner and `PullOverView` stability (#480).

## [1.1.1] - 2026-07-15

### Fixed

- Apple Pay checkout navigation in SwiftUI (#479).

## [1.1.0] - 2026-07-02

### Removed

- Payment method `.tegutEmployeeCard` (#478).

## [1.0.4] - 2026-06-26

### Added

- Persistent receipt archive index and offline receipt browsing (#477).

## [1.0.3] - 2026-06-23

### Added

- Receipt archive action in the receipts list toolbar menu (#476).

## [1.0.2] - 2026-06-05

### Fixed

- Digital coupons (#474).

## [1.0.1] - 2026-06-03

### Added

- `zoomControlOffset` in `ShopperConfiguration`.

### Fixed

- Deduplicate concurrent `AppUser` POST requests in the authenticator (#471, #472).

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
