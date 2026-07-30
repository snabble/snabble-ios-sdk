# MinimalScanAndGo

The smallest possible Snabble ScanAndGo integration — two files, ~200 lines, no router, no AppState, no feature folders.

## What this example shows

- Initialize the SDK and automatically check in to the first available shop
- A single screen with a shop card and a receipt list
- `ShopperView` (scanner + cart + checkout) presented as `.fullScreenCover`
- Navigation to shop details (`ShopView` with map, address, opening hours)
- Receipts loaded and displayed directly via `PurchasesViewModel`

## Structure

```
MinimalScanAndGo/
├── MinimalScanAndGoApp.swift   # @main + Snabble setup
└── ContentView.swift           # Single screen + ShopCard + ShoppingScreen
```

### Setup (`MinimalScanAndGoApp`)

```swift
Snabble.setup(config: config) { snabble in
    guard let project = snabble.projects.first else { return }
    SnabbleCI.register(project)
    snabble.setupProductDatabase(for: project) { _ in
        Task { @MainActor in
            Snabble.shared.checkInManager.shop = firstShop  // auto check-in
            shop = firstShop
        }
    }
}
```

The auto check-in is essential: without it `ShopView` won't show the "Start Shopping" button and `shopsViewModel.actionStream` won't fire.

### Main screen (`ContentView`)

```
List (plain)
├── Section "Einkaufen"
│   └── ShopCard
│       ├── Button → ShopView (map, address, opening hours)
│       └── Button → ShopperView fullscreen (scanner)
└── Section "Kassenbons"
    └── NavigationLink → ReceiptDetailScreen (per receipt)
```

`ShopperView` can be opened two ways:
1. Directly via the scan button on the ShopCard
2. Via the "Start Shopping" button inside `ShopView`, which communicates through `shopsViewModel.actionStream`

```swift
.task {
    for await _ in shopsViewModel.actionStream {
        showShopper = true
    }
}
```

## SDK packages used

| Package | Purpose |
|---------|---------|
| `SnabbleCore` | `Shop`, `Config`, `Snabble`, `SnabbleCI` |
| `SnabbleTheme` | Base theming |
| `SnabbleComponents` | `.actionState()` for toasts and dialogs |
| `SnabbleScanAndGo` | `Shopper`, `ShopperView` |
| `SnabbleShops` | `ShopsViewModel`, `ShopView` |
| `SnabbleReceipts` | `PurchasesViewModel`, `ReceiptsItemView`, `ReceiptDetailScreen` |

## Running

```bash
open Example/MinimalScanAndGo/MinimalScanAndGo.xcodeproj
# Select scheme: MinimalScanAndGo
# Press ⌘R
```

> Uses the **staging** environment with demo credentials (`snabble-sdk-demo-app-oguh3x`).

## Intentionally omitted

- **No `AssetProviding`** — `Asset.provider` is optional; the SDK falls back to its defaults
- **No router** — navigation is driven directly by `@State` flags and `navigationDestination`
- **No AppState object** — the shop is passed as a `let` parameter
- **No feature folders** — everything is flat in two files
