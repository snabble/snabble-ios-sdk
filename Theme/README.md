# SnabbleTheme

**Layer:** 2 (UI Primitives)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleComponents, SnabbleAssetProviding, KeychainAccess

## Overview

SnabbleTheme provides theme management, asset loading, and shared UI utilities for the Snabble iOS SDK. It is the central integration point between the Core data layer and the visual presentation layer.

**Note:** This module was renamed from `SnabbleAssets` to `SnabbleTheme` on 2026-03-27.

## Purpose

- Project registration and asset initialization
- Remote asset downloading and caching (logos, icons)
- Payment method icon resolution
- Developer mode and environment switching
- Barcode rendering (QR, EAN, Code128, PDF417)
- Shared UIKit utilities (SelectionSheet, NSLayoutConstraint helpers, etc.)

## Public API

### Project Registration

`SnabbleCI.register` is the main entry point. It registers the active project and automatically triggers asset initialization:

```swift
import SnabbleTheme

// Register the active project (call once during app setup)
SnabbleCI.register(project)

// Access the currently registered project
let project = SnabbleCI.project
```

### Asset Initialization

For multi-project setups, initialize assets explicitly:

```swift
import SnabbleTheme

// Initialize assets for multiple projects
SnabbleCI.initializeAssets(for: projects) {
    // Called on main thread when done
}

// Initialize with a known manifest URL
SnabbleCI.initializeAssets(for: project.id, manifestUrl, downloadFiles: true)
```

### Asset Retrieval

```swift
import SnabbleTheme

// Async retrieval
let logo = await SnabbleCI.getAsset(.storeLogo, projectId: project.id)

// Callback-based retrieval (called on main thread)
SnabbleCI.getAsset(.storeLogo, projectId: project.id) { image in
    imageView.image = image
}
```

### ImageAsset

```swift
public enum ImageAsset {
    case storeIcon          // 24x24 store icon
    case storeLogo          // Store logo (home view, store detail)
    case storeLogoSmall     // Store logo small (scanner/card title)
    case customerCard       // Customer/loyalty card
    case startTeaserLoyalty
    case startTeaserPayment
    case checkoutOnline
    case checkoutOffline
    case appBackgroundImage
}
```

### Payment Method Icons

```swift
import SnabbleTheme

// icon is an instance property on PaymentMethodDetail
let icon: UIImage? = paymentMethodDetail.icon
```

### Developer Mode

```swift
import SnabbleTheme

// Check if developer mode is active (read-only)
if DeveloperMode.isEnabled { }

// Toggle developer mode (shows password prompt)
DeveloperMode.toggle()

// Read/set the API environment
let env = DeveloperMode.environmentMode          // .staging or .production
DeveloperMode.setEnvironmentMode(.staging)

// Via UserDefaults
UserDefaults.standard.developerMode = true
```

## Key Components

### Asset System
- `AssetManager` (actor) – downloads and caches remote project assets
- `ImageAsset` – typed enum for all asset keys
- `SnabbleCI` – public bridge for project registration and asset access

### Barcode Rendering
- `QRCode`, `Code128`, `PDF417` – barcode generators
- `EANView` – SwiftUI view for EAN barcodes

### Shared UI
- `SnabbleEmptyView` – SwiftUI empty state view
- `SelectionSheetController` – UIKit action sheet alternative
- `DynamicFont` – dynamic type support
- `TextFieldLimitModifier` – SwiftUI text field character limit
- `NSLayoutConstraint` extensions (identifier, priority, variable)

### Utilities
- `DeveloperMode` – dev/staging environment management
- `BuildConfig` – debug/release flags
- `IBANFormatter+UI` – IBAN display formatting
- `ExitToken+Image` – exit token QR image generation

## Dependencies

### Internal
- **SnabbleCore** – `Project`, `Shop`, `PaymentMethodDetail`, and other data models
- **SnabbleComponents** – UI trait system integration
- **SnabbleAssetProviding** – `Asset` protocol and localization utilities

### External
- **KeychainAccess** – secure storage for developer mode credentials
- **WCAG-Colors** – color contrast validation

## Migration Notes

### From SnabbleAssets (pre 2026-03-27)

```swift
// Before
import SnabbleAssets

// After
import SnabbleTheme
```

All public APIs remain unchanged — only the module name changed.

## See Also

- [SnabbleAssetProviding](../AssetProviding/README.md) – Asset protocol definitions
- [SnabbleComponents](../Components/README.md) – SwiftUI UI primitives
- [SnabbleCore](../Core/README.md) – Project and data models
