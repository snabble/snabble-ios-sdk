# SnabbleCore

**Layer:** 1 (Foundation)
**Status:** Active
**Dependencies:** SnabbleNetwork, GRDB, ZIPFoundation, SwiftOTP

## Overview

SnabbleCore is the foundation module of the Snabble iOS SDK. It contains all business logic, data models, offline functionality, and the main SDK API. All other SDK modules depend on Core.

**Architecture Note:** Core has **no circular dependencies** (resolved 2026-03-27). It only depends on Layer 1 modules (Network) and external libraries.

## Purpose

- Central SDK configuration and initialization
- Business logic for shopping, checkout, and payments
- Offline-first data synchronization (GRDB)
- Shopping cart management
- Product database and lookup
- Order history
- Coupon management
- Location-based check-in

## Public API

### SDK Initialization

```swift
import SnabbleCore

// Configure the SDK
let config = Config(
    appId: "your-app-id",
    secret: "your-secret",
    environment: .production
)

// Initialize — completion receives the Snabble instance when ready
Snabble.setup(config: config) { snabble in
    print("SDK initialized: \(snabble.projects.count) project(s)")
}

// Access singleton
let snabble = Snabble.shared
```

### Product Lookup

```swift
let provider = snabble.productProvider(for: project)

// Lookup by barcode
if let result = provider.productBy(codes: [ScannedCode(lookupCode: "1234567890", ...)])  {
    print("Found: \(result.product.name)")
}
```

### Check-In

```swift
// Start automatic location-based check-in
snabble.checkInManager.startUpdating()

// Stop location updates
snabble.checkInManager.stopUpdating()

// Current checked-in shop (imperative)
if let shop = snabble.checkInManager.shop {
    print("Checked in at: \(shop.name)")
}

// SwiftUI — observable state (updates views automatically)
let state = snabble.checkInManager.state  // CheckInState (@Observable)
Text(state.shop?.name ?? "Not checked in")
```

## Key Components

### 1. SDK Configuration
- `Snabble.swift` — Main SDK singleton, `Config` struct, and `Environment` enum
- `SDKVersion.swift` — Version information
- `TokenRegistry.swift` — Authorization token management
- `Core.swift` — `CoreProviding` protocol and `ShoppingCartMerging` extension point

### 2. Shopping Cart
- `ShoppingCart.swift` — Cart implementation
- `ShoppingCartManager.swift` — Multi-cart management (`Snabble.shared.shoppingCartManager`)
- `CartData.swift` / `CartEvent.swift` — Cart data models and events
- `OfflineCarts.swift` — Offline persistence
- `ShoppingCartProviding.swift` — Protocol for cart access

### 3. Product Database
- `ProductDatabase.swift` — GRDB-based local database
- `ProductDatabase+Lookup.swift` — Barcode lookup
- `ProductDatabase+Network.swift` — Sync with backend
- `ProductProviding.swift` — Product lookup protocol
- `ProductStoring.swift` — Database write protocol
- `ScannedProduct.swift` — Result of a barcode scan

### 4. Barcode & Code Handling
- `EAN/EAN.swift` — EAN barcode parsing and validation
- `GS1/GS1Code.swift` — GS1 application identifier parsing
- `QRCode/QRCodeGenerator.swift` — QR code generation
- `API/CodeTemplates.swift` — Configurable code templates

### 5. Checkout & Orders
- `Cart/CheckoutData.swift` — Checkout payload models
- `Cart/CheckoutRequests.swift` — Checkout API requests
- `Cart/CheckoutProcess+Checks.swift` — Pre-checkout validation
- `Orders/OrderList.swift` — Receipt history
- `Orders/PurchaseProviding.swift` — Purchase data protocol

### 6. Payments
- `Payment/Payment.swift` — Payment method definitions
- `Payment/PaymentMethodDetails.swift` — Stored payment details
- `Payment/MethodRegistry.swift` — Payment method registry (`Snabble.methodRegistry`)
- `Payment/IBAN.swift` / `IBANFormatter.swift` — SEPA/IBAN support
- `Payment/Giropay.swift` — Giropay integration
- `Payment/ApplePay.swift` — Apple Pay support
- `Payment/Data/` — Encrypted payment data for various providers (Datatrans, PayOne, TeleCash, …)

### 7. Location & Check-In
- `Checkin/CheckInManager.swift` — Location-based shop check-in (uses `CLLocationManager` internally)
- `Checkin/CheckInState.swift` — `@Observable` state for SwiftUI integration
- `Metadata/Shop.swift` — Shop/store data model

### 8. Metadata & Projects
- `Metadata/Metadata.swift` — App-level configuration fetched from API
- `Metadata/Project.swift` — Multi-tenant project model
- `Metadata/Link.swift` — API endpoint discovery (`MetadataLinks`)
- `Metadata/EntryToken/` — Entry token support (Autonomo, Wanzel)

### 9. Coupons & Shopping List
- `Coupons/CouponManager.swift` — Coupon loading and state
- `Coupons/Coupon.swift` — Coupon model
- `ShoppingList/ShoppingList.swift` — Shopping list support

### 10. User & Utilities
- `User/Client.swift` — Device client identifier
- `User/UserProviding.swift` — User data protocol
- `Events/AppEvents.swift` — Analytics event tracking
- `Utilities/Identifier.swift` — Type-safe identifiers

## Architecture

```
SnabbleCore (Layer 1)
    ├── API Layer
    │   ├── Snabble (singleton + Config + Environment)
    │   ├── TokenRegistry (auth)
    │   └── Core (CoreProviding protocol)
    ├── Shopping Cart
    │   ├── ShoppingCart
    │   └── ShoppingCartManager
    ├── Products
    │   ├── ProductDatabase (GRDB)
    │   └── ProductProviding (protocol)
    ├── Barcodes
    │   ├── EAN
    │   ├── GS1Code
    │   └── CodeTemplates
    ├── Checkout
    │   ├── CheckoutData / CheckoutRequests
    │   └── CheckoutProcess+Checks
    ├── Payments
    │   ├── Payment / MethodRegistry
    │   ├── PaymentMethodDetails
    │   └── Data/ (provider-specific encrypted payloads)
    ├── Orders
    │   └── OrderList
    ├── Check-In
    │   ├── CheckInManager (CLLocationManager wrapper)
    │   └── CheckInState (@Observable, for SwiftUI)
    ├── Metadata
    │   ├── Metadata / Project / Shop
    │   └── EntryToken
    ├── Coupons
    │   └── CouponManager
    └── User
        ├── Client (device ID)
        └── UserProviding (protocol)
```

## Dependencies

### Internal (Layer 1)
- **SnabbleNetwork**: API communication

### External
- **GRDB**: SQLite database for offline functionality
- **ZIPFoundation**: Seed database extraction
- **SwiftOTP**: One-time passwords
- **KeychainAccess**: Secure storage

## Data Persistence

### GRDB Database
- Local product catalog
- Offline cart storage
- Order history cache
- Full-text search support

### Keychain
- Client ID (device identifier)
- User credentials
- Session tokens

### UserDefaults
- Configuration cache
- Check-in state
- Feature flags

## Offline-First Architecture

Core implements offline-first patterns:

1. **Product Database**: Full local product catalog synced from API
2. **Shopping Cart**: Persisted locally, synced when online
3. **Order History**: Cached locally with pagination
4. **Graceful Degradation**: Features work offline where possible

## Migration Notes

### Circular Dependency Resolution (2026-03-27)

Core previously had circular dependencies with User and Components modules. These were resolved:

- **Client.swift**: Moved from User to Core
- **UserProviding**: Moved to Core with type erasure
- **appUser**: Internal accessor in Core, public API in User

## Testing

```bash
# Run Core tests
xcodebuild -scheme SnabbleCoreTests test
```

Test coverage includes:
- Shopping cart logic
- Product lookup
- Barcode parsing
- Cart persistence

## See Also

- [SnabbleNetwork](../Network/README.md) - API communication
- [SnabbleUser](../User/README.md) - User management
