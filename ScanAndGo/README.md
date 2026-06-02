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
- Age verification
- Receipt viewing

## Public API

### Basic Integration

```swift
import SnabbleScanAndGo

// Create shopper instance
let shopper = Shopper(shop: checkedInShop)

// Present complete scan-and-go interface
ShopperView(model: shopper)
    .environmentObject(appState)
```

### SwiftUI Integration

```swift
import SwiftUI
import SnabbleScanAndGo

struct ContentView: View {
    @StateObject var shopper: Shopper

    var body: some View {
        NavigationView {
            if let shop = Snabble.shared.checkedInShop {
                ShopperView(model: Shopper(shop: shop))
            } else {
                ShopSelectionView()
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
- Age verification logic

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
SnabbleScanAndGo (Layer 5)
    ├── Shopper (@Observable)
    │   ├── Shopping state
    │   ├── Scanner control
    │   └── Cart management
    ├── Views (SwiftUI)
    │   ├── ShopperView (main)
    │   ├── Shopping Cart
    │   ├── Scanner
    │   ├── Search
    │   └── Checkout
    ├── Managers
    │   ├── BarcodeManager
    │   └── ActionManager
    └── Models
        ├── ActionState
        └── ScannerState
```

## Dependencies

### Internal
- **SnabbleCore**: Business logic, shopping cart
- **SnabbleComponents**: UI primitives
- **SnabbleTheme**: Theme and assets
- **SnabblePayment**: Checkout integration

### External
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
    @StateObject var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    // Initialize SDK
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
                // Start location-based check-in
                Snabble.shared.checkInManager.startMonitoring()
            case .failure(let error):
                print("SDK setup failed: \(error)")
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            if let shop = Snabble.shared.checkedInShop {
                ShopperView(model: Shopper(shop: shop))
            } else {
                Text("Please check into a shop")
            }
        }
    }
}
```

### Custom Scanner Integration

```swift
import SnabbleScanAndGo

struct CustomShoppingView: View {
    @State var shopper: Shopper

    var body: some View {
        VStack {
            // Your custom header
            CustomHeader()

            // Snabble scan-and-go
            ShopperView(model: shopper)

            // Your custom footer
            CustomFooter()
        }
    }
}
```

## Features

### 1. Barcode Scanning
- Multiple barcode formats (EAN-8, EAN-13, QR, Code 128)
- Real-time detection
- Haptic feedback
- Audio feedback
- Torch/flashlight control
- Zoom controls

### 2. Shopping Cart
- Add/remove products
- Quantity adjustment
- Price display
- Coupon support
- Manual product entry
- Cart persistence

### 3. Search
- Product name search
- Barcode manual entry
- Recent searches
- Auto-suggestions

### 4. Checkout
- Payment method selection
- Age verification
- Final review
- Receipt generation

### 5. Age Verification
- Age-restricted products
- Modal verification flow
- Configurable age limits

## Swift 6 / @Observable Migration

This module was migrated to Swift 6 with `@Observable`:

### Before (ObservableObject)
```swift
class Shopper: ObservableObject {
    @Published var items: [CartItem] = []
}

struct ShopperView: View {
    @StateObject var model: Shopper
}
```

### After (@Observable)
```swift
@Observable
class Shopper {
    var items: [CartItem] = []
}

struct ShopperView: View {
    @State var model: Shopper
}
```

**Migration Notes:**
- All `@Published` removed
- `@StateObject` → `@State`
- `@ObservedObject` → regular property
- No manual `objectWillChange` needed

## Customization

### Theme Customization

```swift
import SnabbleTheme

// Customize colors
AssetManager.shared.register(
    color: .blue,
    for: .primary,
    in: project
)
```

### Scanner Customization

```swift
// Disable haptic feedback
shopper.barcodeManager.hapticFeedbackEnabled = false

// Disable audio feedback
shopper.barcodeManager.audioFeedbackEnabled = false

// Set torch mode
shopper.barcodeManager.torchMode = .on
```

## Testing

Integration testing recommended via:
- Example app (SwiftySnabble)
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

**Benefits:**
- ✅ Pure SwiftUI
- ✅ Better state management
- ✅ Swift 6 compatible
- ✅ More maintainable
- ✅ Better performance

## See Also

- [SnabbleCore](../Core/README.md) - Shopping cart logic
- [SnabbleComponents](../Components/README.md) - UI primitives
- [SnabblePayment](../Payment/README.md) - Checkout integration
- [SDK Architecture Guide](../documentation/SDK-Architecture.md)
