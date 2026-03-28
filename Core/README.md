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

// Initialize
Snabble.setup(config: config) { result in
    switch result {
    case .success:
        print("SDK initialized")
    case .failure(let error):
        print("Initialization failed: \(error)")
    }
}

// Access singleton
let snabble = Snabble.shared
```

### Shopping Cart

```swift
// Get shopping cart for current project
let cart = snabble.shoppingCart(for: projectId)

// Add product
cart.add(product, quantity: 2)

// Remove item
cart.remove(item)

// Get total
let total = cart.total
```

### Product Lookup

```swift
// Lookup by barcode
if let product = productDB.product(forCode: "1234567890") {
    print("Found: \(product.name)")
}

// Search by name
let results = productDB.search(for: "Milk")
```

### Check-In

```swift
// Manual check-in
snabble.checkInManager.checkIn(shop: shop)

// Automatic location-based check-in
snabble.checkInManager.startMonitoring()

// Current checked-in shop
if let shop = snabble.checkedInShop {
    print("Checked in at: \(shop.name)")
}
```

## Key Components

### 1. SDK Configuration
- `Snabble.swift` - Main SDK singleton
- `Config.swift` - Configuration model
- `SDKVersion.swift` - Version information
- `Environment.swift` - API environments

### 2. Shopping Cart
- `ShoppingCart.swift` - Cart implementation
- `ShoppingCartManager.swift` - Multi-cart management
- `CartEntry.swift` - Cart item model
- `OfflineCarts.swift` - Offline persistence

### 3. Product Database
- `ProductDatabase.swift` - GRDB-based local database
- `ScannableCode.swift` - Barcode handling
- `ProductProvider.swift` - Product lookup

### 4. Checkout & Orders
- `CheckoutProcess.swift` - Checkout workflow
- `OrderList.swift` - Receipt history
- `PaymentMethodInfo.swift` - Payment method data

### 5. Location & Check-In
- `CheckInManager.swift` - Shop check-in
- `LocationManager.swift` - Location services
- `Shop.swift` - Shop/store data model

### 6. Metadata & Projects
- `Metadata.swift` - App configuration
- `Project.swift` - Multi-tenant projects
- `Links.swift` - API endpoint discovery

## Architecture

```
SnabbleCore (Layer 1)
    ├── API Layer
    │   ├── Snabble (singleton)
    │   ├── TokenRegistry (auth)
    │   └── Config (configuration)
    ├── Shopping Cart
    │   ├── ShoppingCart
    │   └── ShoppingCartManager
    ├── Products
    │   ├── ProductDatabase (GRDB)
    │   └── ScannableCode
    ├── Checkout
    │   ├── CheckoutProcess
    │   └── PaymentMethodInfo
    ├── Orders
    │   └── OrderList
    ├── Check-In
    │   ├── CheckInManager
    │   └── LocationManager
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

See `documentation/Circular-Dependencies-Analysis.md` for details.

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

## Usage Examples

### Complete Setup

```swift
import SnabbleCore

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

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

        return true
    }
}
```

### Shopping Flow

```swift
import SnabbleCore

// Get cart
let cart = Snabble.shared.shoppingCart(for: project.id)

// Scan product
if let product = productDB.product(forCode: scannedCode) {
    cart.add(product, quantity: 1)
}

// Checkout
let checkoutInfo = cart.checkoutInfo
// Pass checkoutInfo to payment module
```

## See Also

- [SnabbleNetwork](../Network/README.md) - API communication
- [SnabbleUser](../User/README.md) - User management
- [SDK Architecture Guide](../documentation/SDK-Architecture.md)
- [Circular Dependencies Analysis](../documentation/Circular-Dependencies-Analysis.md)
