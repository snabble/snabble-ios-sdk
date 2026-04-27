# Snabble iOS SDK - Architecture Guide

This guide explains the structure and architecture of the Snabble iOS SDK for developers working with the codebase.

## Overview

The Snabble iOS SDK is a modular Swift Package Manager-based retail SDK that provides self-scanning and checkout functionality for iOS applications. It uses a **clean layered architecture** with distinct module responsibilities and **no circular dependencies** (resolved 2026-03-27).

See `documentation/Circular-Dependencies-Analysis.md` for details about the resolved circular dependencies.

## Module Architecture

The SDK follows a strict layered architecture:

![Architecture Diagram](architecture.svg)

```
Layer 1 (Foundation) → Layer 2 (UI Primitives) → Layer 3 (Domain Features) → Layer 4 (Payment) → Layer 5 (Complete Flows)
```

Modules can only depend on modules from lower layers, ensuring no circular dependencies.

### Core Modules

#### 1. **SnabbleCore** - Business Logic & Data
**Location:** `Core/Sources/`

The foundation of the SDK containing all business logic, data models, and offline functionality.

**Key Components:**
- **API Layer** (`API/`)
  - `Snabble.swift` - Main SDK entry point and configuration
  - `Project+Network.swift` - Network requests for projects
  - `TokenRegistry.swift` - Authentication token management
  - `SDKVersion.swift` - Version information

- **Shopping Cart** (`Cart/`)
  - `ShoppingCart.swift` - Main shopping cart implementation
  - `ShoppingCartManager.swift` - Manages multiple carts
  - `CartData.swift` - Cart data models
  - `CheckoutProcess.swift` - Checkout workflow
  - `OfflineCarts.swift` - Offline cart persistence (GRDB)

- **Product Database** (`Products/`)
  - `ProductDatabase.swift` - Local product database (GRDB)
  - `ScannableCode.swift` - Barcode/code handling
  - `ProductProvider.swift` - Product lookup and search

- **Metadata** (`Metadata/`)
  - `Project.swift` - Project/tenant configuration
  - `Shop.swift` - Store location data
  - `Metadata.swift` - App configuration metadata

- **Check-In** (`Checkin/`)
  - `CheckInManager.swift` - Automatic store check-in (location-based)

- **Coupons** (`Coupons/`)
  - `Coupon.swift` - Coupon data model
  - `CouponManager.swift` - Coupon activation/management

- **Orders** (`Orders/`)
  - `OrderList.swift` - Receipt history

**Dependencies:**
- GRDB.swift (SQLite database)
- KeychainAccess (secure storage)

---

#### 2. **SnabbleScanAndGo** - Complete SwiftUI Scan & Shop
**Layer:** 5 (Complete Flows)
**Location:** `ScanAndGo/Sources/`

**⭐ Modern SwiftUI implementation - use this for new features!**

**Main Entry Point:**
```swift
let shopper = Shopper(shop: myShop)
ShopperView(model: shopper)
```

**Key Components:**
- **Shopper** (`Shopper.swift`)
  - `@Observable` class - main scan-and-go state manager
  - Manages cart, scanner, actions, and workflow

- **Views** (`Views/`)
  - `ShopperView.swift` - Main container (replaces `ScannerViewController`)
  - `ShoppingCartView.swift` - SwiftUI cart list
  - `CartEntry.swift` - Cart item views
  - `ProductDetailView.swift` - Product details
  - `CheckoutView.swift` - Checkout flow

- **Scanner** (`Scanner/`)
  - `BarcodeManager.swift` - @Observable barcode detection
  - `CameraView.swift` - SwiftUI camera interface

- **Actions** (`Actions/`)
  - `ActionManager.swift` - @Observable action handler
  - User actions (add to cart, remove, checkout, etc.)

**Architecture Pattern:**
- @Observable ViewModels (Swift 6.2)
- @State for view observation
- @Environment for dependency injection

---

#### 3. **SnabbleNetwork** - API Communication
**Layer:** 1 (Foundation)
**Location:** `Network/Sources/`

**Key Components:**
- API communication layer
- Authentication token management
- AppUser keychain storage
- Configurable protocol

**Dependencies:**
- SwiftOTP, KeychainAccess

---

#### 4. **SnabbleComponents** - UI Primitives
**Layer:** 2 (UI Primitives)
**Location:** `Components/Sources/`

**Key Components:**
- Reusable SwiftUI components
- Buttons, dialogs, toasts
- Web views
- User notification toggles

**Dependencies:**
- SnabbleAssetProviding, WindowKit
- **No Core dependency** ✅ (improved 2026-03-28)

---

#### 5. **SnabbleTheme** - Theme & Assets
**Layer:** 2 (UI Primitives)
**Location:** `Theme/Sources/`

**Key Components:**
- Asset management
- Theme provider
- Project trait system (moved from Components 2026-03-28)
- Custom colors and fonts

**Dependencies:**
- SnabbleCore, SnabbleComponents, SnabbleAssetProviding, KeychainAccess

---

#### 6. **SnabbleUser** - User Management
**Layer:** 3 (Domain Features)
**Location:** `User/Sources/`

**Key Components:**
- User profile management
- Client ID & AppUser public API
- Consent management
- UserProviding protocol

**Dependencies:**
- SnabbleAssetProviding, SnabbleNetwork, SnabbleComponents, SnabbleCore

---

#### 7. **SnabblePayment** - Payment Processing
**Layer:** 4 (Payment)
**Location:** `Payment/Sources/`

**Key Components:**
- Payment method management
- Multi-provider support (Payone, Datatrans, Apple Pay)
- Payment UI (UIKit & SwiftUI)
- Checkout flow integration

**Dependencies:**
- SnabbleCore, SnabbleComponents, SnabbleTheme, SnabbleCart, SnabbleReceipts, SnabbleAssetProviding, SnabbleUser, DeviceKit

---

#### 8. **SnabbleDatatrans** - Datatrans Payment (Optional)
**Layer:** 4 (Payment)
**Location:** `Datatrans/Sources/`

**Payment Methods:**
- Twint
- PostFinance Card

**Setup Required:**
```swift
// In AppDelegate
DatatransFactory.initialize()

// In Info.plist
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>your-url-scheme</string>
    </array>
  </dict>
</array>
```

---

#### 9. **SnabbleAssetProviding** - Asset Protocol
**Layer:** 1 (Foundation)
**Location:** `AssetProviding/Sources/`

**Key Components:**
- Asset protocol definitions
- Color and font protocols
- Localization strings (8 languages)

**Dependencies:**
- WCAG-Colors

**Customization:**
```swift
extension YourApp: AssetProviding {
    func image(named: String) -> UIImage? {
        // Custom images
    }
}

Asset.provider = YourApp()
```

---

## Additional Modules

### Domain Features (Layer 3)
- **SnabbleShops**: Shop management and location services
- **SnabbleCart**: Shopping cart UI components
- **SnabbleReceipts**: Receipt history and PDF viewer
- **SnabbleCoupons**: Coupon management and UI
- **SnabbleTeaser**: Marketing teasers
- **SnabbleOnboarding**: Onboarding flows

### Complete Flows (Layer 5)
- **SnabblePhoneAuth**: Phone number authentication

For detailed documentation on specific modules, see their individual README files in:
- `Core/README.md`
- `Network/README.md`
- `User/README.md`
- `Components/README.md`
- `Theme/README.md`
- `Payment/README.md`
- `ScanAndGo/README.md`

---

## Legacy Components

The following directories contain legacy code that has been mostly replaced:
- **UI/**: Legacy UIKit utilities (see `UI/README.md`)
- **ShopFinder/**: Empty directory marked for removal (see `ShopFinder/README.md`)
  - `SecondaryButtonView.swift`
  - `ButtonStyles.swift`

- **Dialogs** (`SwiftUI/View/Dialog/`)
  - `BottomSheet.swift`
  - `WindowDialog.swift`

- **Toast** (`SwiftUI/View/Toast/`)
  - `Toast.swift` - Toast notifications
  - `Toaster.swift` - Toast manager

- **Web Views** (`SwiftUI/View/Web/`)
  - `WebView.swift` - SwiftUI web view
  - `HTMLView.swift` - HTML rendering
  - `YouTubeView.swift` - YouTube player

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌──────────────────────┐      ┌─────────────────────────┐ │
│  │ SnabbleScanAndGo     │      │ SnabbleUI (Legacy)      │ │
│  │ - ShopperView        │      │ - ScannerViewController │ │
│  │ - @Observable VMs    │      │ - UIKit Components      │ │
│  └──────────┬───────────┘      └────────────┬────────────┘ │
└─────────────┼──────────────────────────────┼───────────────┘
              │                              │
              ▼                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ SnabbleCore                                           │  │
│  │ - ShoppingCart (cart management)                      │  │
│  │ - ProductDatabase (GRDB, offline-first)               │  │
│  │ - CheckoutProcess (checkout workflow)                 │  │
│  │ - CouponManager (coupon activation)                   │  │
│  └────────────────────┬─────────────────────────────────┘  │
└─────────────────────────┼─────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ SnabbleNetwork  │  │ SnabblePayment   │  │ GRDB Database │ │
│  │ - API Requests  │  │ - Payments       │  │ - Products    │ │
│  │ - Auth Tokens   │  │ - Providers      │  │ - Carts       │ │
│  └─────────────────┘  └──────────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Integration Patterns

### 1. SwiftUI Scan-and-Go (Recommended)

```swift
import SnabbleScanAndGo

struct ContentView: View {
    @State private var shopper: Shopper

    init(shop: Shop) {
        _shopper = State(initialValue: Shopper(shop: shop))
    }

    var body: some View {
        ShopperView(model: shopper)
    }
}
```

### 2. Shop Check-In

```swift
import SnabbleCore

Snabble.shared.checkInManager.delegate = self
Snabble.shared.checkInManager.startUpdating()

extension MyViewController: CheckInManagerDelegate {
    func checkInManager(_ manager: CheckInManager, didCheckInTo shop: Shop) {
        // User entered shop
    }
}
```

### 3. Shopping Cart Management

```swift
import SnabbleCore

let cart = Snabble.shared.shoppingCartManager.shoppingCart(for: shop)
cart.add(product, quantity: 1)
cart.remove(cartItem)

// Observe changes
NotificationCenter.default.addObserver(
    self,
    selector: #selector(cartUpdated),
    name: .snabbleCartUpdated,
    object: cart
)
```

### 4. Payment Methods

```swift
import SnabblePayment

NavigationStack {
    PaymentMethodListView(
        projectId: project.id,
        analyticsDelegate: analyticsDelegate
    )
}
```

### 5. Product Lookup

```swift
import SnabbleCore

let db = project.productProvider
db.productBySku("123456") { product in
    // Found product
}

db.productByScannableCode("1234567890123") { lookup in
    // Found scanned product
}
```

---

## Swift 6.2 Migration Status

**Current Status:** ✅ Complete (Phase 1-4)

### ViewModels Migrated to @Observable

**ScanAndGo Module:**
- `Shopper` ✅
- `BarcodeManager` ✅
- `ActionManager` ✅

**UI Module:**
- `ShoppingCartViewModel` ✅
- `PaymentMethodManager` ✅
- `CouponViewModel` ✅
- `CheckoutModel` ✅
- 16 more... (see migration docs)

### Usage Pattern

**Before (ObservableObject):**
```swift
@StateObject var viewModel: ShoppingCartViewModel
```

**After (@Observable):**
```swift
@State var viewModel: ShoppingCartViewModel
```

See `documentation/Swift-6-Migration.md` for the complete migration reference.

---

## Project Structure Reference

```
snabble-ios-sdk/
├── Package.swift                    # SPM package definition
├── README.md                        # Installation guide
├── CLAUDE.md                        # AI coding assistant guide
├── SKILL.md                         # This file
│
├── Core/                            # SnabbleCore module
│   ├── Sources/
│   │   ├── API/                    # Core SDK, networking
│   │   ├── Cart/                   # Shopping cart logic
│   │   ├── Products/               # Product database (GRDB)
│   │   ├── Metadata/               # Projects, shops
│   │   ├── Checkin/                # Location-based check-in
│   │   ├── Coupons/                # Coupon management
│   │   └── Orders/                 # Receipt history
│   └── Tests/
│
├── UI/                              # SnabbleUI module (legacy UIKit)
│   ├── Sources/
│   │   ├── Scanner/                # Camera scanner (Pulley drawer)
│   │   ├── ShoppingCart/           # Cart UI (legacy)
│   │   ├── Payment/                # Payment UI
│   │   ├── Receipts/               # Receipt viewer
│   │   ├── Coupons/                # Coupon UI (new SwiftUI version ✅)
│   │   └── Utilities/              # Helpers, extensions
│   └── Tests/
│
├── ScanAndGo/                       # SnabbleScanAndGo module (modern SwiftUI)
│   ├── Sources/
│   │   ├── Shopper.swift           # Main @Observable model
│   │   ├── ShopperView.swift       # Main entry point
│   │   ├── Views/                  # SwiftUI views
│   │   ├── Scanner/                # Barcode manager
│   │   └── Actions/                # Action manager
│   └── Tests/
│
├── Network/                         # SnabbleNetwork module
│   └── Sources/                    # API client, endpoints
│
├── Datatrans/                       # SnabbleDatatrans (optional)
│   └── Sources/                    # Twint, PostFinance
│
├── User/                            # SnabbleUser module
│   └── Sources/                    # User management
│
├── AssetProviding/                  # SnabbleAssetProviding module
│   └── Sources/
│       ├── Resources/              # Localizations (8 languages)
│       └── Asset.swift             # Theming API
│
├── Components/                      # SnabbleComponents module
│   └── Sources/SwiftUI/
│       └── View/                   # Reusable SwiftUI components
│
├── Example/                         # Example app
│   └── Snabble/
│       ├── AppDelegate.swift
│       └── ScannerViewController.swift
│
└── documentation/
    ├── Swift-6-Migration-Plan.md   # Migration plan (German)
    ├── Swift-6-Migration-Plan-EN.md # Migration plan (English)
    └── SDK-Consumer-Migration-Guide.md # Consumer upgrade guide
```

---

## Common Tasks

### Add a New Product to Cart
```swift
import SnabbleCore

let cart = Snabble.shared.shoppingCartManager.shoppingCart(for: shop)
cart.add(product, scannedCode: code)
```

### Customize UI Theme
```swift
import SnabbleAssetProviding

class MyAssetProvider: AssetProviding {
    func color(named: String) -> UIColor? {
        switch named {
        case "primary": return .systemBlue
        default: return nil
        }
    }
}

Asset.provider = MyAssetProvider()
```

### Handle Payment Completion
```swift
extension MyViewController: PaymentDelegate {
    func checkoutFinished(_ cart: ShoppingCart, _ process: CheckoutProcess?) {
        navigationController?.popToRootViewController(animated: true)
    }

    func exitToken(_ exitToken: ExitToken, for shop: Shop) {
        // Show exit gate QR code
    }
}
```

### Access Receipts
```swift
import SnabbleCore

OrderList.load(project) { result in
    switch result {
    case .success(let orderList):
        let receipts = orderList.receipts
    case .failure(let error):
        print("Error loading receipts: \(error)")
    }
}
```

---

## Testing Strategy

- **Unit Tests:** Each module has dedicated test targets
- **Integration Tests:** Use `Example/SnabbleSampleApp` for end-to-end testing
- **CI/CD:** GitHub Actions with Xcode 16.4, iPhone 16 simulator (iOS 18.5)

---

## Dependencies

### External
- **GRDB.swift** - SQLite database for offline functionality
- **KeychainAccess** - Secure credential storage
- **Datatrans** - PostFinance/Twint payment integration (optional)
- **SwiftOTP** - One-time password functionality

### Internal
- Modular architecture - avoid cross-module dependencies except through defined interfaces
- Use protocol-based abstractions (`ShoppingCartProviding`, `ProductProvider`, etc.)

---

## Development Guidelines

1. **Use SwiftUI for new UI** - Prefer `SnabbleScanAndGo` module
2. **Use @Observable** - All new ViewModels use @Observable (Swift 6.2)
3. **Offline-first** - Use GRDB for all data that needs offline access
4. **Async/await** - Use Swift concurrency for network operations
5. **Protocol abstractions** - Define interfaces in Core, implement in modules

---

## Getting Help

- **Migration Guide:** `documentation/SDK-Consumer-Migration-Guide.md`
- **Migration Plan:** `documentation/Swift-6-Migration-Plan-EN.md`
- **Code Patterns:** `CLAUDE.md`
- **GitHub Issues:** https://github.com/snabble/iOS-SDK/issues

---

**Last Updated:** 2026-02-26
**SDK Version:** 1.0.0 (Swift 6.2)
**Minimum Requirements:** iOS 17.0+, Xcode 17.0+, Swift 6.2
