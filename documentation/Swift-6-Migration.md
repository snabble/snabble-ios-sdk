# Swift 6 Migration Reference

This document describes the completed migration of the Snabble iOS SDK from Swift 5.10 to Swift 6.2. It serves as a reference for SDK consumers updating from 0.x to 1.0, and for contributors working in this codebase.

## Status

Migration complete as of SDK 1.0.0.

- Swift 6 language mode active in all modules
- Full strict concurrency checking (`complete` mode)
- 25 `ObservableObject` classes replaced with `@Observable`
- All UI bugs introduced during migration resolved
- Circular dependencies between modules resolved

## Breaking Changes for SDK Consumers

### ObservableObject replaced by @Observable

All view models previously based on `ObservableObject` now use the `@Observable` macro. This changes how you declare and inject them in SwiftUI views.

```swift
// Before (0.x)
@StateObject var cart = ShoppingCartViewModel(...)
@ObservedObject var cart: ShoppingCartViewModel

// After (1.0+)
@State var cart = ShoppingCartViewModel(...)
var cart: ShoppingCartViewModel           // passed from parent, no wrapper needed
@Environment(ShoppingCartViewModel.self)  // injected via environment
```

`@Published` properties are not used anywhere in the SDK. If you were observing published properties directly, use the `@Observable`-based interface instead.

### Shopper initialization

The `Shopper` model is `@Observable` and `@MainActor` isolated. It must be created on the main actor and held in `@State`:

```swift
@State private var shopper = Shopper(shop: shop)
```

Pass it into the view hierarchy via the environment:

```swift
ShopperView(model: shopper)
```

### Sendable closures

Completion handlers accepted by SDK types are now marked `@Sendable`. If you pass closures to SDK callbacks, they must not capture non-`Sendable` values from outside a concurrency domain.

## Patterns Used in the SDK

### @Observable view models

All state-bearing classes in the SDK follow this pattern:

```swift
import Observation

@Observable
@MainActor
final class MyViewModel {
    var items: [Item] = []
    var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = try? await service.fetchItems() ?? []
    }
}
```

Views own the model lifetime via `@State`:

```swift
struct MyView: View {
    @State private var viewModel = MyViewModel()

    var body: some View {
        List(viewModel.items) { item in ItemRow(item: item) }
            .task { await viewModel.load() }
    }
}
```

### nonisolated delegate callbacks

Framework delegates (AVFoundation, CLLocationManager, etc.) call back on their own queues. The pattern used throughout the SDK is:

```swift
extension MyManager: SomeDelegate {
    nonisolated func delegate(_ d: Any, didReceive value: Value) {
        Task { @MainActor in
            self.handle(value)
        }
    }
}
```

### nonisolated(unsafe) for legacy interop

A small number of properties use `nonisolated(unsafe)` where the calling convention of a third-party framework prevents full actor isolation. These are documented inline and are always protected by either the main thread guarantee or an explicit lock.

### Error presentation

Models do not show alerts or interact with UIKit directly. Instead, they expose error state as observable properties, and the owning view presents the alert via SwiftUI's `.alert()` modifier or `UIAlertController` presented from `self`.

Example from `CheckModel`:

```swift
// In the model
public var onCancelError: (@MainActor () -> Void)?

// In the consuming view controller
checkModel.onCancelError = { [weak self] in
    let alert = UIAlertController(...)
    self?.present(alert, animated: true)
}
```

## Module-Level Changes

### SnabbleCore

- All public protocols annotated with `@MainActor` where appropriate
- `CheckoutProcess` update callbacks wrapped in `Task { @MainActor in ... }`
- `CheckModel`: removed direct `AlertView` usage; consumers configure `onCancelError`

### SnabblePayment

- `CheckModel`, `SepaDataModel`, `SepaAcceptModel`, `InvoiceLoginProcessor` converted to `@Observable`
- `AlertView` (UIKit-window-based alert helper) removed entirely; replaced with native `UIAlertController` presented from `self` in UIKit view controllers, and SwiftUI `.alert()` in SwiftUI views
- `BaseCheckCheckViewController`: `onCancelError` wired in `init`

### SnabbleScanAndGo

- `Shopper`, `BarcodeManager`, `ActionManager` converted to `@Observable`
- `ShopperView` and all subviews are pure SwiftUI with no UIKit dependencies
- `ActionModifier` renamed to `ShopperActionModifier`, view extension renamed from `.actionState()` to `.shopperActions()`

### SnabbleShops

- `ShopsViewModel` converted to `@Observable`
- All shop views are pure SwiftUI

### SnabbleTheme

- `AlertView.swift` deleted (was a `UIWindow`-based alert presenter; no longer needed)
- `DeveloperMode.ask()` now presents `UIAlertController` from the foreground window scene's root view controller

## Known Remaining UIKit Usage

The following areas intentionally remain UIKit-based due to third-party SDK requirements or platform constraints:

- **SnabbleDatatrans** — wraps the Datatrans UIKit SDK for Twint and PostFinance payments
- **Legacy scanner** (`ScannerViewController`) — depends on the Pulley drawer library; deprecated, targeted for removal in 2.0
- **Checkout steps view controller** — complex animated checkout flow; SwiftUI migration deferred to 2.0
- **QLPreviewController** — no SwiftUI equivalent for receipt PDF preview

## Resolved Bugs

Four rendering bugs were identified and fixed during the migration, all caused by computed properties depending on non-observable nested objects:

**Cart item not appearing on first add**
`cartIsEmpty` depended on `shoppingCart.numberOfItems` (non-observable). Changed to `self.items.isEmpty`.

**Price flickering in cart rows**
`Text("")` placeholders caused layout shifts when `regularPriceString` was nil. Fixed with `.opacity(regularPriceString != nil ? 1 : 0)`.

**Total price flickering in cart footer**
Same root cause. Fixed with `.opacity(0)` on the invisible placeholder.

**Checkout total flickering**
`CheckoutView` used an empty string `""` as placeholder, causing height differences. Fixed with a hidden `"0,00 €"` placeholder.

## Checklist for Contributors

When adding a new class or view model:

- Use `@Observable` and `@MainActor` for any class that holds UI state
- Do not use `ObservableObject`, `@Published`, or `@StateObject`
- Mark completion handlers as `@Sendable` when they cross actor boundaries
- Do not call `AlertView`, `UIAlertController`, or any UIKit alert API from within a model
- Use `async/await` and `Task` instead of `DispatchQueue` or `Timer`
- Computed properties in `@Observable` classes must depend only on other observable stored properties
