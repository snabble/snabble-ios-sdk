# SnabbleAssetProviding

**Layer:** 1 (Foundation)
**Status:** Active
**Dependencies:** WCAG-Colors

## Overview

SnabbleAssetProviding is the SDK's customization foundation. It defines the `AssetProviding` protocol and the `Asset` static dispatch layer that all SDK modules use to look up images, colors, strings, fonts, and button styles. By implementing `AssetProviding` and registering a provider at startup, the host app can override any SDK asset with its own branding.

## Purpose

- Define the `AssetProviding` protocol for host-app customization
- Provide the `Asset` static facade used throughout the SDK
- Define named semantic colors (`projectPrimary`, `navigationBar`, etc.)
- Provide the `ViewProvider` system for injecting custom views into SDK screens
- Bundle default assets and localizations (de, en, fr, fr-CH, hu, it, sk)
- Bundle `Country` and `CallingCode` models

## Setup

Register a provider once during app initialization, before any SDK views appear:

```swift
import SnabbleAssetProviding

// Register your custom provider
Asset.provider = AppAssetProvider()

// Set the active domain (project ID) for per-project asset resolution
Asset.domain = project.id
```

## Implementing AssetProviding

`AssetProviding` is a typealias for all sub-protocols:

```swift
public typealias AssetProviding = ImageProviding
                                & ColorProviding
                                & StringProviding
                                & UrlProviding
                                & FontProviding
                                & StyleProviding
```

Minimal implementation (return `nil` to fall back to SDK defaults):

```swift
import SnabbleAssetProviding

final class AppAssetProvider: AssetProviding {

    // MARK: - ImageProviding
    func image(named name: String, domain: Any?) -> UIImage? {
        UIImage(named: name)
    }
    func image(named name: String, domain: Any?) -> SwiftUI.Image? {
        guard UIImage(named: name) != nil else { return nil }
        return SwiftUI.Image(name)
    }

    // MARK: - ColorProviding
    func color(named name: String, domain: Any?) -> UIColor? {
        UIColor(named: name)
    }

    // MARK: - StringProviding
    func localizedString(forKey key: String, arguments: CVarArg..., domain: Any?) -> String? {
        let value = Bundle.main.localizedString(forKey: key, value: key, table: nil)
        return value != key ? String.localizedStringWithFormat(value, arguments) : nil
    }

    // MARK: - UrlProviding
    func url(forResource name: String?, withExtension ext: String?, domain: Any?) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
    }

    // MARK: - FontProviding
    func font(_ name: String, size: CGFloat?, relativeTo textStyle: Font.TextStyle?, domain: Any?) -> Font? {
        nil // return nil to use system font
    }

    // MARK: - StyleProviding
    func primaryButtonBackground(domain: Any?) -> (any View)? { nil }
    func primaryBorderedButtonBackground(domain: Any?) -> (any View)? { nil }
    func secondaryButtonBackground(domain: Any?) -> (any View)? { nil }
    func primaryButtonRadius(domain: Any?) -> CGFloat? { nil }
    func buttonFontWeight(domain: Any?) -> Font.Weight? { nil }
    func buttonFont(domain: Any?) -> Font? { nil }
    func primaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? { nil }
    func secondaryButtonConfiguration(domain: Any?) -> UIButton.Configuration? { nil }
}
```

Returning `nil` from any method causes `Asset` to fall back to the SDK bundle's default.

## Asset Facade

The `Asset` enum is the single lookup point used by all SDK modules:

```swift
// Colors
UIColor.projectPrimary()          // UIColor
Color.projectPrimary()            // SwiftUI Color

// Images
Asset.image(named: "my-icon")     // UIImage?
Image.image(named: "my-icon")     // SwiftUI Image (falls back to SF Symbol)

// Strings
Asset.localizedString(forKey: "Snabble.ok")

// URLs
Asset.url(forResource: "terms", withExtension: "html")

// Fonts
Asset.font("MyFont", size: 16, relativeTo: .body, domain: nil)
```

## Named Semantic Colors

`UIColor` and `SwiftUI.Color` are extended with project-specific semantic colors. All fall back to SDK defaults if not provided by the `AssetProviding` implementation:

| Color name | Key | Default |
|---|---|---|
| `projectPrimary()` | `"primary"` | Snabble blue `#0077BB` |
| `onProjectPrimary()` | `"onPrimary"` | Auto-contrast |
| `projectSecondary()` | `"secondary"` | Same as primary |
| `onProjectSecondary()` | `"onSecondary"` | Auto-contrast |
| `projectNavigationBar()` | `"navigationBar"` | `.systemBackground` |
| `onProjectNavigationBar()` | `"onNavigationBar"` | Auto-contrast |
| `projectFaq()` | `"faq"` | `.lightGray` |
| `systemGreen()` | `"systemGreen"` | `.systemGreen` |
| `systemRed()` | `"systemRed"` | `.systemRed` |
| `badge()` | `"badge"` | `.systemRed` |
| `border()` | `"border"` | `.systemGray` |
| `shadow()` | `"shadow"` | `.systemGray3` |

In your asset catalog, name colors using the key column above and they will be picked up automatically.

## ViewProvider

`ViewProvider` lets the host app inject custom SwiftUI views into specific SDK screens:

```swift
import SnabbleAssetProviding

// Register a custom view at startup
ViewProviderStore.register(view: { MyRatingView() }, for: .ratingAccessory)
ViewProviderStore.register(view: { MySuccessView() }, for: .successCheckout)
```

Available injection points:

| Key | Location |
|---|---|
| `.ratingAccessory` | Checkout success screen — rating prompt |
| `.successCheckout` | Checkout success screen — main content |
| `.receiptsEmpty` | Receipts list — empty state |
| `.paymentsEmpty` | Payment methods list — empty state |

In SDK code, the view is used via the property wrapper:

```swift
@ViewProvider(.successCheckout) var successView: AnyView
```

If no view is registered, `AnyView(EmptyView())` is returned.

## Bundled Resources

SnabbleAssetProviding bundles default resources used as fallbacks:

- **Localizations:** de, en, fr, fr-CH, hu, it, sk (`Localizable.strings` / `.stringsdict`)
- **`Snabble.xcassets`** – default SDK images and colors
- **`countries.json`** – `Country` and `Country.State` data (ISO codes, names)
- **`calling-codes.json`** – `CallingCode` data (country + phone dialing codes)

### Country & CallingCode

```swift
import SnabbleAssetProviding

// All countries
let countries = Country.all

// All calling codes
let callingCodes = CallingCode.all

// Look up by code
let germany = CallingCode.germany
let germanyCountry = Country.germany
```

## Key Types

| Type | Description |
|---|---|
| `AssetProviding` | Typealias for all sub-protocols — implement this in your app |
| `Asset` | Static facade for all asset lookups across the SDK |
| `ViewProvider` | Property wrapper for injectable custom views |
| `ViewProviderStore` | Registry for custom view factories |
| `Country` | ISO country model with states |
| `CallingCode` | Country + phone dialing code model |

## See Also

- [SnabbleTheme](../Theme/README.md) – Implements `AssetProviding` and manages remote project assets
- [SnabbleComponents](../Components/README.md) – Uses `Asset` for all colors, images, and strings
