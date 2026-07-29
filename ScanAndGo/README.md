# SnabbleScanAndGo

**Layer:** 5 (Complete Flows)
**Status:** Active - Primary Scan & Go Implementation
**Dependencies:** SnabbleCore, SnabbleComponents, SnabbleTheme, SnabblePayment

## Overview

SnabbleScanAndGo provides a complete, ready-to-use SwiftUI implementation of the scan-and-go shopping workflow. It's the recommended way to integrate Snabble's self-scanning functionality into your app.

**Migration Status:** This module replaced the legacy UIKit scanner (SnabbleUI) during the Swift 6 migration (2026-03).

## Purpose

- Complete scan-and-go shopping workflow
- Camera-based barcode scanning
- Shopping cart management UI
- Product search and manual entry
- Checkout flow integration
- Receipt viewing

## Public API

### Basic Integration

```swift
import SnabbleScanAndGo

// Create shopper instance
let shopper = Shopper(shop: checkedInShop)

// React to checkout completion
shopper.onCheckoutCompleted = { success in
    if success {
        // navigate away
    }
}

// Present complete scan-and-go interface
ShopperView(model: shopper)
```

### ShopperConfiguration

`ShopperView` accepts an optional `ShopperConfiguration` to adjust layout offsets for embedding in a custom container:

```swift
ShopperView(
    model: shopper,
    configuration: .init(
        drawerOffset: 100,       // bottom offset for the cart drawer (default: 0)
        zoomControlOffset: 100,  // bottom offset for the zoom control (default: 100)
        showDismiss: false       // show/hide the built-in dismiss button (default: true)
    )
)
```

### SwiftUI Integration

The recommended pattern is to own `Shopper` at app-state level so it survives view re-renders and active payment flows:

```swift
import SwiftUI
import SnabbleScanAndGo

@Observable
@MainActor
final class AppState {
    var shopper: Shopper?

    func updateShopper(for shop: Shop) {
        // Only recreate when the shop changes to avoid interrupting active payment flows
        guard shopper?.cartModel.shoppingCart.shopId != shop.id else { return }
        shopper = Shopper(shop: shop)
    }
}

struct ShoppingView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        if let shopper = appState.shopper {
            ShopperView(model: shopper, configuration: .init(showDismiss: false))
                .onAppear {
                    shopper.onCheckoutCompleted = { success in
                        // handle navigation
                    }
                }
        }
    }
}
```

## Key Components

### 1. Shopper (ViewModel)
- **@Observable** view model (Swift 6)
- Manages shopping session state
- Coordinates scanner, cart, checkout
- Handles barcode detection
- `onCheckoutCompleted: (@MainActor (Bool) -> Void)?` — callback after checkout
- `Shopper(shop:)` for simple setup; `Shopper(shop:detector:)` to inject a custom barcode detector

### 2. ShopperView
- Main container view
- Camera scanner
- Cart drawer (Pulley-style)
- Search interface
- Checkout flow

### 3. BarcodeManager
- Camera session management
- Barcode detection (AVFoundation)
- Multi-format support (EAN, QR, etc.)
- Scanning feedback (haptics, sounds)

### 4. Shopping Cart Views
- `ShoppingCartView` - Cart list
- `CartItemView` - Individual items
- `ShoppingCartFooterView` - Total/checkout
- Real-time updates

### 5. Checkout Views
- `CartCheckoutBarView` - Payment selection and checkout action bar
- `PaymentSelectionView` - Payment methods
- `PaymentButtonView` - Quick checkout

## Architecture

```
ScanAndGo/
    ├── Sources/
    │   ├── Models/
    │   │   ├── Shopper.swift (@Observable)
    │   │   ├── BarcodeManager.swift
    │   │   ├── BarcodeDetector.swift
    │   │   └── ScannerDelegate.swift
    │   └── Views/
    │       ├── ShopperView.swift (main)
    │       ├── ShoppingScannerView.swift
    │       ├── ScannerCartView.swift
    │       ├── CartCheckoutBarView.swift
    │       ├── PaymentSelectionView.swift
    │       └── ScanMessageView.swift
    └── README.md
```

## Dependencies

### Internal
- **SnabbleCore**: Business logic, product lookup, shopping cart model
- **SnabbleAssetProviding**: Localization, assets, colors
- **SnabbleComponents**: UI primitives, HUD modifier, CardShape
- **SnabbleTheme**: Theme and branding
- **SnabbleCart**: Cart views (ShoppingCartView, CartItemView, etc.)
- **SnabblePayment**: Payment method selection and checkout flow

### External
- **CameraZoomWheel**: Zoom control UI for the scanner
- **AVFoundation**: Camera and barcode scanning
- **SwiftUI**: UI framework
- **Observation**: @Observable macro

## Usage

### Complete Setup

```swift
import SwiftUI
import SnabbleScanAndGo
import SnabbleCore

@main
struct MyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    await setupSnabble()
                }
        }
    }

    func setupSnabble() async {
        let config = Config(
            appId: "your-app-id",
            secret: "your-secret"
        )

        Snabble.setup(config: config) { result in
            switch result {
            case .success:
                Snabble.shared.checkInManager.startMonitoring()
            case .failure(let error):
                print("SDK setup failed: \(error)")
            }
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        if let shop = Snabble.shared.checkedInShop {
            ShopperView(model: Shopper(shop: shop))
        } else {
            Text("Please check into a shop")
        }
    }
}
```

### Custom Scanner (Camera Only)

To embed just the scanner camera without the full ShopperView (no cart drawer, no checkout),
use `BarcodeScanner` directly with your own `BarcodeDetector`:

```swift
import SwiftUI
import SnabbleScanAndGo
import CameraZoomWheel

struct CustomBarcodeScannerView: View {
    let detector: any BarcodeDetecting
    @State private var zoomLevel: CGFloat = 1
    @State private var zoomSteps: [ZoomStep] = ZoomStep.defaultSteps

    var body: some View {
        ZStack(alignment: .bottom) {
            BarcodeScanner(detector: detector)
            ScannerOverlay(offset: .constant(0))
            ZoomControl(zoomLevel: $zoomLevel, steps: zoomSteps)
        }
        .onChange(of: zoomLevel) {
            detector.zoomFactor = zoomLevel
        }
        .onAppear { detector.start() }
        .onDisappear { detector.stop() }
    }
}
```

`BarcodeScanner` and `ScannerOverlay` are public types in `SnabbleScanAndGo`.
The detector is typically created via `BarcodeDetectorImplementation.projectDefault.createBarcodeDetector(for:)`.

## Features

### 1. Barcode Scanning
- Supported formats: EAN-8, EAN-13 (incl. UPC-A), Code 128, Code 39, ITF-14, QR, DataMatrix
- Active formats are configured per project in the Snabble backend (`project.scanFormats`)
- Real-time detection
- Haptic feedback
- Torch/flashlight control
- Zoom controls (via CameraZoomWheel)

### 2. Shopping Cart
- Add/remove products
- Quantity adjustment
- Price display
- Coupon support
- Manual product entry
- Cart persistence

### 3. Manual Barcode Entry
- Type the beginning of a barcode to find matching products (prefix search on barcode codes)
- Uses numeric keyboard — not a product name search
- Option to add an unrecognized code directly

### 4. Checkout
- Payment method selection
- Final review
- Receipt generation

## Swift 6 / @Observable

This module uses Swift 6 with `@Observable` and `@MainActor`:

```swift
@Observable
@MainActor
final class Shopper {
    var items: [CartItem] = []
}

struct ShopperView: View {
    let model: Shopper
}
```

**Key patterns:**
- `@State` for owning an `@Observable` in a view
- Regular `let` property for non-owning references
- `@Environment(MyType.self)` instead of `@EnvironmentObject`
- No `@Published`, no `objectWillChange`

## Customization

### Scanner Customization

```swift
// Disable haptic feedback
shopper.barcodeManager.hapticFeedbackEnabled = false

// Disable audio feedback
shopper.barcodeManager.audioFeedbackEnabled = false
```

## Testing

Integration testing recommended via:
- UI tests with XCUITest
- Manual QA with physical devices

**Note:** Camera functionality requires physical devices or simulator with camera support.

## Troubleshooting

### Camera Not Working
```swift
// Check camera permissions
AVCaptureDevice.authorizationStatus(for: .video)

// Request permissions
AVCaptureDevice.requestAccess(for: .video) { granted in
    if granted {
        // Initialize scanner
    }
}
```

### Barcode Not Scanning
- Ensure adequate lighting
- Check barcode format support
- Verify product exists in database
- Check scanner state

### Cart Not Updating
- Verify `@State` wrapper on Shopper
- Check SwiftUI view updates
- Ensure proper `@Observable` usage

## Migration from Legacy UI

### Old (UIKit SnabbleUI)
```swift
let scannerVC = ScannerViewController()
present(scannerVC, animated: true)
```

### New (SwiftUI ScanAndGo)
```swift
ShopperView(model: Shopper(shop: shop))
```

## See Also

- [SnabbleCore](../Core/README.md) - Business logic, product database, barcode formats
- SnabbleCart - Cart views embedded in the scanner drawer (no README yet)
- [SnabbleComponents](../Components/README.md) - UI primitives, HUD modifier
- [SnabblePayment](../Payment/README.md) - Checkout integration
