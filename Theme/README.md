# SnabbleTheme

**Layer:** 2 (UI Primitives)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleComponents

## Overview

SnabbleTheme provides theme and asset management for the Snabble iOS SDK. It implements the `SnabbleAssetProviding` protocol and integrates with Core to provide a consistent visual identity across all SDK components.

**Note:** This module was renamed from `SnabbleAssets` to `SnabbleTheme` on 2026-03-27 to better reflect its purpose.

## Purpose

- Theme management (colors, fonts, images)
- Asset loading and caching
- Project-specific branding
- Accessibility support (WCAG color contrast)
- Developer mode utilities

## Public API

### Asset Manager

```swift
import SnabbleTheme

// Access global asset manager
let assetManager = AssetManager.shared

// Get project-specific colors
let primaryColor = assetManager.color(for: .primary, in: project)

// Get project-specific images
let logo = assetManager.image(named: "logo", for: project)
```

### Payment Method Assets

```swift
// Get payment method icon
let icon = PaymentMethodDetail.icon(for: .creditCard)

// Get payment method color
let color = PaymentMethodDetail.color(for: .sepaDebit)
```

### Developer Mode

```swift
// Toggle developer mode features
DeveloperMode.isEnabled = true
```

## Key Features

### 1. Theme System
- Project-specific color schemes
- Automatic dark mode support
- WCAG-compliant color contrast
- SF Symbols integration

### 2. Asset Management
- Efficient asset loading and caching
- Project-specific branding
- Fallback assets for missing resources
- Image and icon management

### 3. Accessibility
- WCAG color contrast validation
- High-contrast mode support
- Accessible color utilities

## Architecture

```
SnabbleAssetProviding (Protocol - Layer 1)
         ↓ implements
SnabbleTheme (Implementation - Layer 2)
         ↓ uses
SnabbleCore (Project data)
SnabbleComponents (UI traits)
```

## Dependencies

### Required
- **SnabbleCore**: Project and shop data models
- **SnabbleComponents**: UI trait system
- **SnabbleAssetProviding**: Protocol definitions

### External
- **WCAG-Colors**: Color contrast validation

## Usage Examples

### Custom Color Theme

```swift
import SnabbleTheme

// Define custom colors for a project
extension AssetManager {
    func setupCustomTheme(for project: Project) {
        register(color: .blue, for: .primary, in: project)
        register(color: .green, for: .accent, in: project)
    }
}
```

### Payment Method Icons

```swift
import SnabbleTheme

struct PaymentMethodRow: View {
    let method: RawPaymentMethod

    var body: some View {
        HStack {
            Image(systemName: PaymentMethodDetail.icon(for: method))
            Text(method.displayName)
        }
        .foregroundColor(PaymentMethodDetail.color(for: method))
    }
}
```

## Migration Notes

### From SnabbleAssets (Pre-2026-03-27)

The module was renamed from `SnabbleAssets` to `SnabbleTheme` to better describe its purpose:

**Old:**
```swift
import SnabbleAssets
```

**New:**
```swift
import SnabbleTheme
```

All public APIs remain unchanged - only the module name changed.

## Testing

SnabbleTheme does not currently have dedicated unit tests. Testing is performed through:
- Integration tests in consumer apps
- Visual regression testing
- Accessibility audits

## See Also

- [SnabbleAssetProviding](../AssetProviding/README.md) - Protocol definition
- [SnabbleComponents](../Components/README.md) - UI primitives
- [SDK Architecture Guide](../documentation/SDK-Architecture.md)
