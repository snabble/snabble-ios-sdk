# Snabble iOS SDK

![License](https://img.shields.io/github/license/mashape/apistatus.svg)
![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)
[![Actions Status](https://github.com/snabble/snabble-ios-sdk/workflows/Lint/badge.svg)](https://github.com/snabble/snabble-ios-sdk/actions)
[![Contact](https://img.shields.io/badge/Contact-%40snabble__io-blue)](https://twitter.com/snabble_io)

Self-scanning and checkout SDK for iOS, built with Swift 6 and SwiftUI.

## Requirements

- Xcode 17.0 or later
- iOS 17.0 or later
- Swift 6.2

## Installation

### Swift Package Manager via Xcode

Select `File` > `Add Package Dependencies...` in Xcode, then enter the repository URL:

```
https://github.com/snabble/snabble-ios-sdk.git
```

Set the dependency rule to `Up to Next Major Version` starting from `1.0.0`, then select the products you need.

### Package.swift

```swift
dependencies: [
    .package(
        url: "https://github.com/snabble/snabble-ios-sdk.git",
        .upToNextMajor(from: "1.0.0")
    )
]
```

Add the desired products to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SnabbleScanAndGo", package: "Snabble"),
    ]
)
```

## Architecture

The SDK is organized into five layers with no circular dependencies:

**Layer 1 — Foundation**
- `SnabbleCore` — business logic, data models, cart management, offline database (GRDB)
- `SnabbleNetwork` — API communication and authentication
- `SnabbleAssetProviding` — theming and asset management

**Layer 2 — UI Primitives**
- `SnabbleComponents` — reusable SwiftUI components
- `SnabbleTheme` — asset management with Core integration

**Layer 3 — Domain Features**
- `SnabbleShops` — shop and store views
- `SnabbleCart` — shopping cart UI
- `SnabbleUser` — user management
- `SnabbleReceipts` — receipt display

**Layer 4 — Payment**
- `SnabblePayment` — payment processing with multiple provider support

**Layer 5 — Complete Flows**
- `SnabbleScanAndGo` — complete Scan & Go workflow (`ShopperView`)
- `SnabblePhoneAuth` — phone-based authentication
- `SnabbleCoupons` — coupon management
- `SnabbleOnboarding` — onboarding flows

## Integration

### Scan & Go

`SnabbleScanAndGo` provides a complete, self-contained Scan & Go interface. It handles barcode scanning, cart management, payment method selection, and checkout.

Check the user into a shop first, then create a `Shopper`:

```swift
import SnabbleScanAndGo

Snabble.shared.checkInManager.checkIn(shop: shop)
let shopper = Shopper(shop: shop)
```

Present `ShopperView` in a `NavigationStack`:

```swift
import SnabbleScanAndGo

struct ShoppingContainer: View {
    @State private var shopper: Shopper?

    var body: some View {
        NavigationStack {
            if let shopper {
                ShopperView(model: shopper)
            }
        }
    }
}
```

Apply `.shopperActions()` once at the root of your view hierarchy. This modifier connects the `ActionManager` to your UI so that toasts, dialogs, sheets, and alerts triggered during a session are actually displayed. Without it, these overlays will be silently swallowed.

```swift
RootView()
    .environment(router)
    .shopperActions()
```

`ShopperView` covers the full session lifecycle:

- Barcode scanning with camera and manual entry
- Shopping cart management (quantities, deletion)
- Payment method selection and configuration
- Checkout with error handling

### Payment Methods (optional, standalone)

```swift
import SnabblePayment

NavigationStack {
    PaymentMethodListView(
        projectId: project.id,
        analyticsDelegate: analyticsDelegate
    )
}
```

### Optional: Datatrans (Twint, PostFinance)

To enable `twint` and `postFinanceCard`, add `SnabbleDatatrans` to your app and call `DatatransFactory.initialize()` during initialization with your registered URL scheme.

The `Info.plist` also requires a URL scheme entry as described in the [Datatrans SDK documentation](https://docs.datatrans.ch/docs/mobile-sdk).

## Example Project

```bash
git clone https://github.com/snabble/snabble-ios-sdk
cd snabble-ios-sdk/Example
open SnabbleSampleApp.xcodeproj
```

To run the sample app you need an application identifier and a corresponding secret. [Contact us](mailto:info@snabble.io) for access.

## Documentation

Full API reference: https://docs.snabble.io/docs/ios/

## Versioning

The SDK follows [Semantic Versioning](https://semver.org/). Version 1.0.0 introduced Swift 6 language mode and is not backward compatible with 0.x releases. See `documentation/Swift-6-Migration.md` for the migration reference.

## License

snabble is (c) 2021–2026 snabble GmbH, Bonn. The SDK is available under the [MIT License](https://github.com/snabble/iOS-SDK/blob/main/LICENSE).
