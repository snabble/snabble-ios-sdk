# Snabble SDK — Example Apps

Two SwiftUI example apps demonstrating different levels of Snabble SDK integration.

## Available examples

### 1. [MinimalScanAndGo/](../Example/MinimalScanAndGo/) — Minimal integration ⚡️

The smallest possible ScanAndGo integration: one screen, two files, ~200 lines.

**Project:** `MinimalScanAndGo.xcodeproj`

**Highlights:**
- No router, no AppState object, no feature folders
- First available shop selected automatically
- `ShopperView` presented as `.fullScreenCover`
- Receipts via `PurchasesViewModel` — no wrapper needed

**Best for:** Getting started quickly, prototypes, understanding the minimal API surface.

[→ README](../Example/MinimalScanAndGo/MinimalScanAndGo/README.md)

---

### 2. [SwiftySnabble/](./SwiftySnabble/) — Full SwiftUI reference app ⭐️

A complete, production-oriented SwiftUI app with Swift 6.2.

**Project:** `SnabbleSampleApp.xcodeproj` — scheme `SwiftySnabble`

**Highlights:**
- Multi-tab navigation with Router pattern
- `@Observable` state management
- Asset providing, onboarding, profile, payment methods
- Full shop list with search and check-in flow

**Best for:** Learning best practices, using as a template for a real app.

---

## Comparison

| | MinimalScanAndGo | SwiftySnabble |
|---|---|---|
| **Files** | 2 | ~20 |
| **Lines of code** | ~200 | ~1200 |
| **Navigation** | `@State` flags | Router pattern |
| **State** | Inline `@State` | `@Observable` ViewModels |
| **Screens** | 1 | Multi-tab |
| **Asset providing** | Default (none) | Custom `AssetProviding` |
| **Swift version** | 6.2 | 6.2 |

## Running

```bash
# Minimal example
open Example/MinimalScanAndGo/MinimalScanAndGo.xcodeproj

# Full SwiftUI app (open workspace, select SwiftySnabble scheme)
open Snabble.xcworkspace
```

Both apps use the **staging** environment with demo credentials and require no additional setup.

## Testing payments

The staging environment uses TeleCash as the payment provider. Use these test card numbers at checkout:

| Card type | Number | Expiry | CVV |
|-----------|--------|--------|-----|
| Visa | `4242 4242 4242 4242` | any future date | any 3 digits |
| Mastercard | `5555 5555 5555 4444` | any future date | any 3 digits |
| Amex | `3714 4963 5398 431` | any future date | any 4 digits |
