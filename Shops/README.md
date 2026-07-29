# SnabbleShops

**Layer:** 3 (Domain Features)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleTheme

## Overview

SnabbleShops provides SwiftUI views and a ViewModel for browsing and displaying retail shop locations. It handles location-based distance calculation, opening hours, an interactive map, and in-app navigation to shops.

The module is used by `SnabbleCart` (to identify the current shop context) and can be integrated standalone into any app that wants to show a shop list or detail screen.

## Entry Points

### SwiftUI

```swift
import SnabbleShops

// Full shop list with search and navigation to detail view
ShopsView(shops: shops)

// Single shop detail view
ShopView(shop: shop, viewModel: viewModel)

// Map-only embed (e.g. as part of a custom detail layout)
ShopMapView(shop: shop, showNavigationControl: true)
```

### UIKit

```swift
// UIHostingController wrapper for UIKit navigation stacks
let vc = ShopsViewController(shops: shops)
vc.delegate = self
navigationController?.pushViewController(vc, animated: true)
```

## ShopsViewControllerDelegate

Implement `ShopsViewControllerDelegate` to react when the user taps the primary action button on a shop detail view:

```swift
@MainActor
class MyShopsCoordinator: ShopsViewControllerDelegate {

    // Called when the user taps "Shop Now" on the currently checked-in shop
    func shopsViewController(_ viewController: ShopsViewController,
                              didSelectActionOnShop shop: ShopProviding) {
        // e.g. navigate to the scanner
    }
}
```

## ShopProviding

`ShopProviding` is the central protocol of this module. Any type that conforms to it can be displayed throughout all `SnabbleShops` views. `Shop` (from `SnabbleCore`) conforms to it automatically.

```swift
public protocol ShopProviding: AddressProviding, Sendable {
    var id: Identifier<Shop> { get }
    var name: String { get }
    var email: String { get }
    var phone: String { get }
    var street: String { get }
    var postalCode: String { get }
    var city: String { get }
    var country: String { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var openingHoursSpecification: [OpeningHoursSpecification] { get }
}
```

The protocol also provides default implementations for `location: CLLocation` and `distance(from:) -> CLLocationDistance` via an extension.

## Key Components

### ShopsViewModel

`@Observable` class that manages the shop list and location updates:

- Starts/stops `CLLocationManager` updates when the view appears/disappears
- Calculates distances from the user's current location to each shop and sorts the list accordingly
- Exposes an `AsyncStream<ShopProviding>` (`actionStream`) for the primary action button on the detail view
- Detects the currently checked-in shop via `Snabble.shared.checkInManager`

### Views

| File | Purpose |
|------|---------|
| `ShopsView` | Root list view with search bar; navigates to `ShopView` |
| `ShopCellView` | List row showing shop name, address, distance, and a "You are here" badge |
| `ShopView` | Detail screen with map, address, distance/navigation, phone number, and opening hours |
| `ShopMapView` | Interactive `MapKit` map with a shop pin, address callout, and location/navigation controls |
| `AddressView` | Reusable two-line street/city display (backed by `AddressProviding`) |
| `DistanceView` | Formatted distance label (meters or kilometers) |
| `OpeningHoursView` | Grouped opening hours table derived from `OpeningHoursSpecification` |
| `ShopsViewController` | `UIHostingController` wrapper forwarding the action stream to `ShopsViewControllerDelegate` |

### OpeningHourViewModel

Helper model that converts raw `OpeningHoursSpecification` entries into grouped, localised display rows:

- Consecutive days with identical hours are collapsed into a range (e.g. "Monday – Friday")
- 24/7 availability is detected and displayed as a single "24/7" row
- Time strings are converted from server format (`HH:mm`) to the device locale (12 h / 24 h)

## Architecture

```
SnabbleShops (Layer 3)
    ├── ShopsViewController          (UIKit entry point)
    │   └── ShopsView                (SwiftUI root, search + list)
    │       └── ShopCellView         (list row per shop)
    │           └── ShopView         (detail screen)
    │               ├── ShopMapView  (MapKit embed with navigation controls)
    │               ├── AddressView
    │               ├── DistanceView
    │               ├── OpeningHoursView
    │               └── PhoneNumberView (from SnabbleComponents)
    └── ShopsViewModel               (@Observable, location + action stream)
        └── ShopProviding[]
```

## Dependencies

| Module | Role |
|--------|------|
| `SnabbleCore` | `Shop`, `OpeningHoursSpecification`, `CheckInManager`, `Identifier` |
| `SnabbleTheme` | Themed button styles and project colours |
| `SnabbleAssetProviding` | Localised strings, asset lookup |
| `SnabbleComponents` | `PhoneNumberView`, shared UI utilities |

## Used By

- **SnabbleCart** — references `ShopProviding` in the checkout coordinator protocol
- **SnabbleScanAndGo** — can present the shop list as part of the main tab flow

## See Also

- [SnabbleCore](../Core/README.md) — `Shop` model and `CheckInManager`
- [SnabbleCart](../Cart/README.md) — uses `ShopProviding` in its delegate protocol
