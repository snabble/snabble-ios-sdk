# SnabbleReceipts

**Layer:** 3 (Domain Features)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleAssetProviding, SnabbleComponents, SnabbleTheme

## Overview

SnabbleReceipts provides SwiftUI screens for displaying, reading, and archiving purchase receipts. It loads order history from the Snabble backend, renders individual receipts as PDFs via QuickLook, and supports exporting a full local archive of all receipts organized by shop.

## Entry Points

```swift
import SnabbleReceipts

// Drop-in list of all receipts with built-in NavigationStack navigation
ReceiptsListScreen()

// Custom navigation: handle taps yourself via the ViewModel's onAction callback
let viewModel = PurchasesViewModel()
viewModel.onAction = { provider in
    // navigate to ReceiptDetailScreen yourself
}
ReceiptsListScreen(model: viewModel, useBuiltInNavigation: false)

// Show a single receipt by order ID
ReceiptDetailScreen(orderId: order.id, projectId: order.projectId)

// Show a receipt from an archived local PDF
ReceiptDetailScreen(localURL: pdfURL, provider: order)
```

## Key Components

### Views

| View | Purpose |
|------|---------|
| `ReceiptsListScreen` | Paginated list of all orders; pull-to-refresh, unread badge, context menu for mark-as-read |
| `ReceiptDetailScreen` | Renders a single receipt PDF using `QLPreviewController`; supports share and mail-to-support |
| `ArchiveListScreen` | Browses receipts stored in the local archive (loaded from `.index.json`) |
| `ArchiveReceiptsView` | Sheet for downloading all receipts into a dated archive folder with progress display |
| `ReceiptsItemView` | Row view shared across list and archive screens; shows shop image, date, amount, and read indicator |

### Models

| Class / Struct | Purpose |
|----------------|---------|
| `PurchasesViewModel` | `@Observable` view model that loads `OrderList` from the network and tracks read/unread state |
| `ReceiptReadStatusManager` | Singleton that persists the read/unread state of receipt IDs to `UserDefaults` |
| `OrderArchiveManager` | Downloads all receipt PDFs into a local folder structure under `Documents/Order Archive/` |

### Navigation

`ReceiptsListScreen` registers a `.navigationDestination(for: ReceiptNavigationItem.self)` value-based destination. This requires the screen to be placed inside a `NavigationStack`:

```swift
NavigationStack {
    ReceiptsListScreen()
}
```

When `useBuiltInNavigation: false`, the screen calls `PurchasesViewModel.onAction` instead, leaving navigation entirely to the host app.

## Read / Unread State

Receipts are considered unread until the user opens them. `ReceiptReadStatusManager` stores a `Set<String>` of read receipt IDs in `UserDefaults` under `io.snabble.sdk.readReceiptStatus`.

`PurchasesViewModel` exposes:
- `numberOfUnread: Int` — drives the tab badge
- `markAsRead(receiptId:)` / `markAsUnread(receiptId:)` / `markAllAsRead()`

## Receipt Archive

`ArchiveReceiptsView` downloads all available receipts and stores them at:

```
Documents/
  Order Archive/
    <ShopName>/
      <orderId>.pdf
    .index.json   ← list of archived Order objects (ISO 8601 dates)
```

`OrderArchiveManager.hasArchive` returns `true` when `.index.json` exists. The archive can be browsed offline via `ArchiveListScreen` and shared as a folder via the system share sheet.

### Silent archiving

Pass `silent: true` to `ArchiveReceiptsView` to start the download immediately without showing the confirmation prompt — useful for background or triggered archiving flows:

```swift
.sheet(isPresented: $showArchive) {
    ArchiveReceiptsView(orders: viewModel.orders, silent: true)
}
```

## Architecture

```
SnabbleReceipts (Layer 3)
    ├── ReceiptsListScreen         (entry point)
    │   ├── ReceiptsItemView       (list rows)
    │   ├── ArchiveListScreen      (local archive browser)
    │   └── ArchiveReceiptsView    (archive creation sheet)
    │       └── ArchiveListScreen  (shown after successful archive)
    ├── ReceiptDetailScreen        (PDF viewer via QLPreviewController)
    └── PurchasesViewModel         (@Observable, drives list + badge)
        ├── ReceiptReadStatusManager  (UserDefaults persistence)
        └── OrderArchiveManager       (local PDF archive)
```

## Dependencies

| Module | Role |
|--------|------|
| `SnabbleCore` | `Order`, `OrderList`, `PurchaseProviding`, `Snabble.shared` |
| `SnabbleAssetProviding` | `Asset.localizedString`, localized copy |
| `SnabbleComponents` | `AsyncContentView`, `LoadableObject`, `PrimaryButtonView`, `SecondaryButtonView` |
| `SnabbleTheme` | Theming (`ProjectPrimaryButtonStyle`, color helpers) |

## See Also

- [SnabbleCore](../Core/README.md) — `Order`, `OrderList`, and `PurchaseProviding`
- [SnabbleComponents](../Components/README.md) — `AsyncContentView` and shared UI primitives
