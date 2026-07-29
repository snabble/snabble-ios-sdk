# SnabblePayment

**Layer:** 4 (Payment)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleComponents, SnabbleTheme, SnabbleCart, SnabbleReceipts, SnabbleAssetProviding, SnabbleUser, DeviceKit

## Overview

SnabblePayment provides payment method management and checkout integration for the Snabble iOS SDK. The public API is SwiftUI-based; UIKit view controllers exist internally as implementation details wrapped in SwiftUI containers.

## Purpose

- Payment method management (add, edit, delete)
- Multi-provider support (Payone, TeleCash, Datatrans, Apple Pay)
- SwiftUI views for payment method selection and editing
- Checkout process integration
- Payment authorization and processing

## Supported Payment Methods

### Digital Wallets
- **Apple Pay** – Native iOS payment via PassKit
- **Twint** – Swiss mobile payment (via Datatrans)
- **PostFinance Card** – Swiss payment (via Datatrans)

### Cards
- **Credit Card** (Visa, Mastercard, Amex) – via Payone or TeleCash
- **SEPA Direct Debit** – via Payone or legacy SEPA

### Other
- **Giropay** – German online banking payment
- **Invoice** – Buy now, pay later (via login)

## Public API

### Payment Method List

```swift
import SnabblePayment

// Show all payment methods for a specific project
PaymentMethodListView(projectId: project.id, analyticsDelegate: nil)

// Show payment method selection across projects (for multi-retailer setups)
ProjectPaymentSelectionView(analyticsDelegate: nil)

// Show payment methods scoped to a brand
ProjectPaymentSelectionView(brandId: brand.id, analyticsDelegate: nil)
```

### Add Payment Method

Use `RawPaymentMethod.addView(projectId:analyticsDelegate:)` to get the correct add view for any payment method:

```swift
import SnabblePayment

// Get the appropriate add view for a payment method
let addView = rawPaymentMethod.addView(projectId: project.id, analyticsDelegate: nil)
```

Available add view containers per provider:

| Container | Provider |
|---|---|
| `PayoneCreditCardAddView` | Payone credit card |
| `PayoneSepaAddView` | Payone SEPA |
| `TeleCashCreditCardAddView` | TeleCash credit card |
| `SepaAddView` | Legacy SEPA |
| `GiropayAddView` | Giropay |
| `InvoiceLoginAddView` | Invoice with login |
| `DatatransAddView` | Twint / PostFinance |

### Edit Payment Method

```swift
import SnabblePayment

// Edit containers for existing payment methods
PayoneCreditCardEditView(...)
TeleCashCreditCardEditView(...)
SepaEditView(...)
InvoiceLoginEditView(...)
DatatransEditView(...)
```

### Payment Method Manager

```swift
import SnabblePayment

// Manage payment method selection state
let manager = PaymentMethodManager(
    project: project,
    paymentConsumer: consumer,
    delegate: self
)

// Check if any payment methods are available
if manager.hasMethodsToSelect {
    // Show payment selection UI
}

// React to selection changes via delegate
extension MyClass: PaymentMethodManagerDelegate {
    func paymentMethodManager(didSelectItem item: PaymentMethodItem) {
        // Handle item selection
    }

    func paymentMethodManager(didSelectPayment payment: Payment?) {
        // Handle payment selection
    }
}
```

### Checkout Integration

Implement `PaymentDelegate` to integrate the checkout process:

```swift
import SnabblePayment

class MyViewController: UIViewController, PaymentDelegate {

    func checkoutFinished(_ cart: ShoppingCart, _ process: CheckoutProcess?) {
        // Handle checkout completion
    }

    func handlePaymentError(_ method: PaymentMethod, _ error: SnabbleError) -> Bool {
        // Return true if error was handled, false to use default handling
        return false
    }

    func exitToken(_ exitToken: ExitToken, for shop: Shop) {
        // Handle exit token after checkout
    }

    func paymentRequiresNavigation(to viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }
}
```

### Starting a Payment Method Check

```swift
import SnabblePayment

let check = PaymentMethodStartCheck(
    for: paymentMethod,
    detail: paymentMethodDetail,
    on: presentingViewController
)
check.messageDelegate = self
check.startPayment { success in
    if success {
        // Proceed with checkout
    }
}
```

## Architecture

```
SnabblePayment (Layer 4)
    ├── PaymentMethodManager
    ├── PaymentMethodStartCheck
    ├── SwiftUI Views (public)
    │   ├── List
    │   │   ├── PaymentMethodListView
    │   │   ├── ProjectPaymentSelectionView
    │   │   └── PaymentListItemsView
    │   ├── Edit Containers
    │   │   ├── PayoneCreditCardEditView
    │   │   ├── PayoneSepaEditView
    │   │   ├── TeleCashCreditCardEditView
    │   │   ├── SepaEditView
    │   │   ├── GiropayEditView
    │   │   ├── InvoiceLoginEditView
    │   │   └── DatatransEditView
    │   └── Add Containers (via RawPaymentMethod.addView)
    ├── Checkout (internal)
    │   ├── CheckoutStepsViewController
    │   ├── ApplePayCheckoutViewController
    │   └── CheckoutStepsViewModel
    └── Protocols
        ├── PaymentDelegate
        └── PaymentMethodManagerDelegate
```

## Dependencies

### Internal
- **SnabbleCore** – Business logic, checkout process, `RawPaymentMethod`, `Project`
- **SnabbleComponents** – UI primitives and shared views
- **SnabbleTheme** – Payment method icons and colors
- **SnabbleCart** – Shopping cart integration
- **SnabbleReceipts** – Receipt generation after checkout
- **SnabbleAssetProviding** – Asset and localization support
- **SnabbleUser** – User account and credential management

### External
- **DeviceKit** – Device capability detection
- **PassKit** – Apple Pay integration
- **Datatrans** – Twint / PostFinance support (optional, via SnabbleDatatrans)

## See Also

- [SnabbleCore](../Core/README.md) – Checkout process and payment method types
- [SnabbleCart](../Cart/README.md) – Shopping cart
- [SnabbleReceipts](../Receipts/README.md) – Receipt handling
