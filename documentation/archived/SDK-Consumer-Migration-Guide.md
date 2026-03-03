# Snabble iOS SDK - Migration Guide to v1.0 (Swift 6.2)

This guide helps SDK consumers migrate from v0.74.x to v1.0.0, which includes the Swift 6.2 migration with @Observable.

## Breaking Changes

### 1. ObservableObject → @Observable

All ViewModels have been migrated from `ObservableObject` to `@Observable`. This requires changes in your SwiftUI views.

#### Property Wrapper Changes

**Before (v0.74.x):**
```swift
import SwiftUI
import SnabbleScanAndGo

struct MyShoppingView: View {
    @ObservedObject var shopper: Shopper
    @StateObject var viewModel: ShoppingCartViewModel
    @EnvironmentObject var paymentManager: PaymentMethodManager

    var body: some View {
        // Your view code
    }
}
```

**After (v1.0.0):**
```swift
import SwiftUI
import SnabbleScanAndGo

struct MyShoppingView: View {
    @State var shopper: Shopper
    @State var viewModel: ShoppingCartViewModel
    @Environment(PaymentMethodManager.self) var paymentManager

    var body: some View {
        // Your view code
    }
}
```

#### ViewModel Initialization

**Before (v0.74.x):**
```swift
struct ContentView: View {
    @StateObject private var shopper = Shopper(shop: myShop)

    var body: some View {
        ShopperView(model: shopper)
    }
}
```

**After (v1.0.0):**
```swift
struct ContentView: View {
    @State private var shopper = Shopper(shop: myShop)

    var body: some View {
        ShopperView(model: shopper)
    }
}
```

### 2. Combine Publishers Removed

Some ViewModels no longer expose Combine publishers. Use `@State` to observe changes directly:

**Before (v0.74.x):**
```swift
viewModel.$cartItems
    .sink { items in
        // Handle changes
    }
    .store(in: &cancellables)
```

**After (v1.0.0):**
```swift
// In SwiftUI, changes are automatically observed via @State
@State var viewModel: ShoppingCartViewModel

var body: some View {
    ForEach(viewModel.items, id: \.id) { item in
        // SwiftUI automatically updates when items change
    }
}
```

### 3. ViewModel Classes Now @Observable

The following classes are now `@Observable` (no longer `ObservableObject`):

**UI Module:**
- `ShoppingCartViewModel`
- `CartItemModel`, `ProductItemModel`, `CouponCartItemModel`
- `SepaDataModel`, `SepaAcceptModel`, `PaymentSubjectViewModel`
- `InvoiceLoginModel`, `InvoiceLoginProcessor`
- `PaymentMethodManager`, `BaseCheckViewModel`, `RatingModel`
- `LoginViewModel`, `OnboardingViewModel`, `CouponViewModel`, `CheckoutModel`
- `DynamicViewModel`, `StartShoppingViewModel`, `AllStoresViewModel`
- `ConnectWifiViewModel`, `CustomerCardViewModel`

**ScanAndGo Module:**
- `Shopper`
- `BarcodeManager`
- `ActionManager`

## What Stays the Same

### Public API Signatures
All public method names, parameters, and return types remain unchanged:
```swift
// Still works exactly the same
Snabble.setup(config: config) { snabble in
    // Setup code
}

let cart = Snabble.shared.shoppingCartManager.shoppingCart(for: shop)
cart.add(product, quantity: 1)
```

### Protocols & Entry Points
All protocols and entry points remain unchanged:
```swift
// Still the same
ShopperView(model: shopper)  // Main entry point for scan-and-go

// Protocols unchanged
class MyDelegate: PaymentDelegate {
    func checkoutFinished(_ cart: ShoppingCart, _ process: CheckoutProcess?) {
        // Implementation
    }
}
```

### Data Models
All data models (Product, Shop, CartItem, Order, etc.) remain unchanged:
```swift
// Still works
let product = Product(...)
let shop = Snabble.shared.projects.first?.shops.first
```

## Requirements

### Minimum Versions
- **Swift:** 6.2
- **iOS:** 17.0+
- **Xcode:** 17.0+

### Package.swift Changes
Update your Package.swift to require Swift 6.2:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/snabble/iOS-SDK", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "SnabbleCore", package: "iOS-SDK"),
                .product(name: "SnabbleScanAndGo", package: "iOS-SDK")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
```

## Migration Steps

### Step 1: Update SDK Version
```swift
// In Package.swift
.package(url: "https://github.com/snabble/iOS-SDK", from: "1.0.0")
```

### Step 2: Update Property Wrappers
Replace all ViewModel property wrappers in your SwiftUI views:
- `@ObservedObject` → `@State`
- `@StateObject` → `@State`
- `@EnvironmentObject` → `@Environment`

### Step 3: Remove Combine Subscriptions
If you were subscribing to `@Published` properties, remove those subscriptions and rely on SwiftUI's automatic observation.

### Step 4: Test Thoroughly
- Test all shopping cart operations
- Test payment flows
- Test scanner functionality
- Verify real-time UI updates (quantity changes, cart updates, etc.)

## Troubleshooting

### View Not Updating
**Problem:** Your SwiftUI view doesn't update when ViewModel properties change.

**Solution:** Ensure you're using `@State` for @Observable ViewModels:
```swift
@State var viewModel: ShoppingCartViewModel  // ✅ Correct
var viewModel: ShoppingCartViewModel         // ❌ Won't observe changes
```

### Compile Errors with Combine
**Problem:** Compile errors about missing `@Published` properties.

**Solution:** @Observable properties don't use `@Published`. Access them directly:
```swift
// Before
viewModel.$items.sink { ... }

// After
// Use @State in SwiftUI - changes are automatically observed
@State var viewModel: ShoppingCartViewModel
```

### Missing objectWillChange
**Problem:** `objectWillChange` property not found.

**Solution:** @Observable classes don't expose `objectWillChange`. SwiftUI tracks changes automatically through `@State`.

## Getting Help

If you encounter issues during migration:
1. Check the [CLAUDE.md](../CLAUDE.md) for detailed patterns
2. Review the [Migration Plan](Swift-6-Migration-Plan-EN.md) for technical details
3. Open an issue on [GitHub](https://github.com/snabble/iOS-SDK/issues)

## Example Migration

Here's a complete before/after example:

### Before (v0.74.x)
```swift
import SwiftUI
import SnabbleCore
import SnabbleScanAndGo
import Combine

struct ShoppingView: View {
    @StateObject private var shopper: Shopper
    @State private var cancellables = Set<AnyCancellable>()

    init(shop: Shop) {
        _shopper = StateObject(wrappedValue: Shopper(shop: shop))
    }

    var body: some View {
        ShopperView(model: shopper)
            .onAppear {
                shopper.objectWillChange
                    .sink { _ in
                        print("Shopper changed")
                    }
                    .store(in: &cancellables)
            }
    }
}
```

### After (v1.0.0)
```swift
import SwiftUI
import SnabbleCore
import SnabbleScanAndGo

struct ShoppingView: View {
    @State private var shopper: Shopper

    init(shop: Shop) {
        _shopper = State(initialValue: Shopper(shop: shop))
    }

    var body: some View {
        ShopperView(model: shopper)
            .onChange(of: shopper.cart.items) { oldValue, newValue in
                print("Cart items changed")
            }
    }
}
```

---

**Note:** This is a major version update with breaking changes. We recommend thorough testing in a development environment before deploying to production.
