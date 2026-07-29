# SnabbleCart

**Layer:** 3 (Domain Features)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleShops, SnabbleTheme

## Overview

SnabbleCart is the UI layer for the shopping cart. It takes the `ShoppingCart` domain object from SnabbleCore and provides SwiftUI views, a ViewModel, and a delegate protocol for integrating the cart into an app.

The module is used by both `SnabblePayment` and `SnabbleScanAndGo` as the entry point for the checkout flow.

## Entry Points

### SwiftUI

```swift
import SnabbleCart

// Directly from a ShoppingCart
ShoppingCartView(shoppingCart: cart)

// With an existing ViewModel (e.g. to share state between views)
let viewModel = ShoppingCartViewModel(shoppingCart: cart)
ShoppingCartView(cartModel: viewModel)

// Compact mode: hides footer (total + checkout button)
// Used e.g. for a HUD preview inside the scanner
ShoppingCartView(shoppingCart: cart, compactMode: true)
```

### UIKit

```swift
// UIHostingController wrapper for UIKit navigation stacks
let vc = ShoppingCartViewController(shoppingCart: cart)
vc.shoppingCartDelegate = self
navigationController?.pushViewController(vc, animated: true)
```

## ShoppingCartDelegate

Implement `ShoppingCartDelegate` to handle navigation and checkout coordination:

```swift
@MainActor
class MyCartCoordinator: ShoppingCartDelegate {

    // Guard before checkout starts (default implementation: always allows)
    func checkoutAllowed(project: Project, cart: ShoppingCart, completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    // Called when the user initiates payment
    func gotoPayment(_ method: RawPaymentMethod,
                     _ detail: PaymentMethodDetail?,
                     _ info: SignedCheckoutInfo,
                     _ cart: ShoppingCart,
                     _ didStartPayment: @escaping @Sendable (Bool) -> Void) {
        // Create and start a PaymentProcess here
    }

    // Called when the user taps "back to scanner"
    func gotoScanner() {
        navigationController?.popViewController(animated: true)
    }

    // Called on checkout errors; return true if you handled it yourself
    func handleCheckoutError(_ error: SnabbleError) -> Bool {
        return false
    }
}
```

`ShoppingCartDelegate` also inherits `AnalyticsDelegate` (for tracking events) and `MessageDelegate` (for showing messages). Both have default no-op implementations.

## Key Components

### CartEntry

`CartEntry` is the enum that drives the list rows in `ShoppingCartView`. The ViewModel maps the raw `ShoppingCart` data into this type:

| Case | Description |
|------|-------------|
| `.cartItem(CartItem, [LineItem])` | A regular product with its backend line items |
| `.coupon(CartCoupon, LineItem?)` | A user-added coupon |
| `.voucher(CartVoucher, [LineItem])` | A deposit-return voucher |
| `.lineItem(LineItem, [LineItem])` | A backend-only row (e.g. loyalty reward injected by the backend) |
| `.giveaway(LineItem)` | A free item added by the backend |
| `.discount(Int)` | A single row summarising total cart discounts |

### ShoppingCartViewModel

`@Observable @MainActor` class that sits between `ShoppingCart` and the views:

- Listens to `.snabbleCartUpdated` notifications and rebuilds the `CartEntry` list
- Handles SKU replacements: when the backend substitutes a product, it performs an async product lookup and replaces the `CartItem` in-place
- Prefetches product images to fill the URL cache before they appear on screen
- Drives deletion confirmation dialogs (`confirmDeletion`, `processDeletion`, `cancelDeletion`)
- Exposes quantity mutation (`increment`, `decrement`) used by `CartStepperView`
- Computes display totals (`totalString`, `regularTotalString`) using `PriceFormatter`

### Views

| File | Purpose |
|------|---------|
| `ShoppingCartView` | Root view; shows empty state or delegates to `ShoppingCartItemsView` |
| `ShoppingCartItemsView` | Scrollable list of `CartEntry` rows + footer slot |
| `ShoppingCartFooterView` | Total price row and checkout button (hidden in compact mode) |
| `CartItemView` | Row for a `.cartItem` entry |
| `CartStepperView` | +/- stepper embedded in `CartItemView` |
| `CartWeightView` | Weight display for weight-based products |
| `CouponItemView` | Row for a `.coupon` entry |
| `VoucherItemView` | Row for a `.voucher` entry |
| `DiscountItemView` | Row for a `.discount` summary entry |

### View-Specific Models

| File | Purpose |
|------|---------|
| `CartItemModel` | Base observable model for a cart row |
| `ProductItemModel` | Extends `CartItemModel` with quantity mutation |
| `CouponCartItemModel` | Extends `CartItemModel` for coupon rows |

## Architecture

```
SnabbleCart (Layer 3)
    ├── ShoppingCartViewController  (UIKit entry point)
    │   └── ShoppingCartView        (SwiftUI root)
    │       ├── ShoppingCartItemsView
    │       │   ├── CartItemView  ←── ProductItemModel
    │       │   ├── CouponItemView ←── CouponCartItemModel
    │       │   ├── VoucherItemView
    │       │   └── DiscountItemView
    │       └── ShoppingCartFooterView
    └── ShoppingCartViewModel       (@Observable, drives all views)
        └── CartEntry[]             (mapped from ShoppingCart + BackendCartInfo)
```

## Dependencies

| Module | Role |
|--------|------|
| `SnabbleCore` | `ShoppingCart`, `CartItem`, `CartCoupon`, `CheckoutInfo`, `PriceFormatter` |
| `SnabbleShops` | `ShopProviding` (used by `ShoppingCartViewControllerDelegate`) |
| `SnabbleTheme` | Theming and styled components |

## Used By

- **SnabblePayment** — embeds the cart view in the payment flow
- **SnabbleScanAndGo** — embeds the cart view (compact mode) in the scanner HUD

## See Also

- [SnabbleCore](../Core/README.md) — `ShoppingCart` domain logic and persistence
- [SnabblePayment](../Payment/README.md) — checkout and payment processing
