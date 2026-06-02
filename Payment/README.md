# SnabblePayment

**Layer:** 4 (Payment)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleTheme, SnabbleComponents

## Overview

SnabblePayment provides payment processing integration for the Snabble iOS SDK. It supports multiple payment providers and methods, including credit cards, SEPA, digital wallets, and more.

## Purpose

- Payment method management
- Multi-provider support (Payone, Datatrans, Apple Pay)
- Payment method UI (add, edit, delete)
- Checkout process integration
- Payment authorization and processing
- Receipt generation

## Supported Payment Methods

### Digital Wallets
- **Apple Pay** - Native iOS payment
- **Google Pay** - (Android only, reference implementation)
- **Twint** - Swiss mobile payment (via Datatrans)
- **PostFinance Card** - Swiss payment (via Datatrans)

### Cards
- **Credit Card** (Visa, Mastercard, Amex) - via Payone
- **Debit Card** - Various networks
- **SEPA Direct Debit** - European bank transfers

### Other
- **Invoice** - Buy now, pay later
- **External Billing** - Third-party payment

## Public API

### Payment Method List

```swift
import SnabblePayment

// Get available payment methods for project
let methods = PaymentMethodManager.availableMethods(for: project)

// Show payment method list (UIKit)
let paymentVC = PaymentMethodListViewController(project: project)
navigationController?.pushViewController(paymentVC, animated: true)

// Show payment method list (SwiftUI)
PaymentMethodListView(project: project)
```

### Add Payment Method

```swift
import SnabblePayment

// Add credit card (Payone)
let addVC = PayoneCreditCardEditViewController(
    brand: .visa,
    prefillData: userInfo,
    projectId: project.id
)
present(addVC, animated: true)

// Add SEPA
let sepaVC = SepaEditViewController(projectId: project.id)
present(sepaVC, animated: true)
```

### Process Checkout

```swift
import SnabblePayment

// Get selected payment method
guard let method = PaymentMethodManager.selectedMethod else {
    // Show payment selection
    return
}

// Start checkout
let checkoutVC = CheckoutViewController(
    cart: cart,
    paymentMethod: method
)
present(checkoutVC, animated: true)
```

## Key Components

### 1. Payment Method Manager
- Available methods discovery
- Payment method storage
- Method selection
- Validation

### 2. Payment UI (UIKit)
- `PaymentMethodListViewController` - Method list
- `PayoneCreditCardEditViewController` - Add/edit card
- `SepaEditViewController` - Add/edit SEPA
- `CheckoutViewController` - Checkout flow

### 3. Payment UI (SwiftUI)
- `PaymentMethodListView` - Method list
- `PaymentEditContainers` - Add/edit views
- `CheckoutView` - Checkout flow

### 4. Payment Processing
- Provider integrations (Payone, Datatrans)
- Authorization flow
- Error handling
- Receipt generation

## Architecture

```
SnabblePayment (Layer 4)
    ├── Payment Methods
    │   ├── PaymentMethodManager
    │   ├── RawPaymentMethod (enum)
    │   └── PaymentMethodInfo
    ├── UI (UIKit)
    │   ├── List
    │   │   ├── PaymentMethodListViewController
    │   │   └── UserPaymentViewController
    │   ├── Edit
    │   │   ├── PayoneCreditCardEditViewController
    │   │   ├── SepaEditViewController
    │   │   └── InvoiceLoginViewController
    │   └── Checkout
    │       ├── CheckoutViewController
    │       └── CheckoutStepsViewController
    ├── UI (SwiftUI)
    │   ├── PaymentMethodListView
    │   ├── PaymentEditContainers
    │   └── CheckoutView
    └── Providers
        ├── Payone (credit cards)
        └── Apple Pay (native)
```

## Dependencies

### Internal
- **SnabbleCore**: Business logic, checkout process
- **SnabbleTheme**: Payment method icons and colors
- **SnabbleComponents**: UI primitives

### External (Optional)
- **SnabbleDatatrans**: Twint/PostFinance support
- **PassKit**: Apple Pay integration

## Payment Method Types

### RawPaymentMethod Enum

```swift
public enum RawPaymentMethod: String {
    case qrCodePOS          // QR code at POS terminal
    case qrCodeOffline      // Offline QR code
    case externalBilling    // Third-party billing
    case deDirectDebit      // SEPA direct debit
    case creditCardVisa     // Visa
    case creditCardMastercard // Mastercard
    case creditCardAmericanExpress // Amex
    case applePay          // Apple Pay
    case googlePay         // Google Pay
    case twint             // Twint (Datatrans)
    case postFinanceCard   // PostFinance (Datatrans)
    case invoiceByLogin    // Invoice
    // ... more
}
```

## Usage

### Complete Payment Flow

```swift
import SnabblePayment
import SnabbleCore

class PaymentCoordinator {

    // 1. Check if payment method is selected
    func startCheckout(cart: ShoppingCart) {
        guard let method = PaymentMethodManager.selectedMethod else {
            showPaymentSelection()
            return
        }

        processCheckout(cart: cart, method: method)
    }

    // 2. Show payment selection
    func showPaymentSelection() {
        let paymentVC = PaymentMethodListViewController(
            project: currentProject
        )
        navigationController?.pushViewController(paymentVC, animated: true)
    }

    // 3. Process checkout
    func processCheckout(cart: ShoppingCart, method: PaymentMethodInfo) {
        let checkoutVC = CheckoutViewController(
            cart: cart,
            paymentMethod: method
        )

        checkoutVC.onCompletion = { result in
            switch result {
            case .success(let receipt):
                self.showReceipt(receipt)
            case .failure(let error):
                self.showError(error)
            }
        }

        present(checkoutVC, animated: true)
    }
}
```

### Apple Pay Integration

```swift
import SnabblePayment
import PassKit

// Check Apple Pay availability
if PKPaymentAuthorizationController.canMakePayments() {
    // Show Apple Pay option
}

// Configure Apple Pay
let paymentRequest = PKPaymentRequest()
paymentRequest.merchantIdentifier = "merchant.io.snabble.app"
paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
paymentRequest.merchantCapabilities = .capability3DS
paymentRequest.countryCode = "DE"
paymentRequest.currencyCode = "EUR"
paymentRequest.paymentSummaryItems = [
    PKPaymentSummaryItem(label: "Total", amount: cart.total)
]

// Present Apple Pay
let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
controller.present { success in
    print("Apple Pay: \(success)")
}
```

### SEPA Direct Debit

```swift
import SnabblePayment

// Add SEPA payment method
let sepaData = SepaData(
    iban: "DE89370400440532013000",
    name: "John Doe"
)

SepaManager.add(sepaData, for: project) { result in
    switch result {
    case .success:
        print("SEPA added")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Datatrans Integration (Twint/PostFinance)

```swift
import SnabbleDatatrans

// Initialize Datatrans (in AppDelegate)
DatatransFactory.initialize(urlScheme: "myapp://")

// Add Twint
let twintVC = DatatransAliasViewController(
    method: .twint,
    project: project
)
present(twintVC, animated: true)
```

## Testing

### Test Mode

```swift
// Enable test mode in configuration
config.useTestEnvironment = true

// Use test card numbers
// Visa: 4111 1111 1111 1111
// Mastercard: 5500 0000 0000 0004
```

### UI Testing

```swift
// Test payment method list
func testPaymentMethodList() {
    let vc = PaymentMethodListViewController(project: testProject)
    // Verify methods are loaded
    XCTAssertGreaterThan(vc.methods.count, 0)
}
```

## Security

### PCI DSS Compliance

- **No card data stored locally** - All sensitive data handled by payment providers
- **Tokenization** - Card details replaced with tokens
- **3D Secure** - Supported for enhanced security
- **Encryption** - All communication encrypted (TLS 1.2+)

### Best Practices

```swift
// ❌ NEVER log payment data
print(creditCard.number) // DON'T DO THIS

// ✅ Use tokens
print(creditCard.token) // OK

// ❌ NEVER store CVV
UserDefaults.standard.set(cvv, forKey: "cvv") // DON'T

// ✅ Use Keychain for tokens only
Keychain.set(paymentToken, forKey: "payment_token") // OK
```

## Customization

### Custom Payment Method Icons

```swift
import SnabbleTheme

extension PaymentMethodDetail {
    static func customIcon(for method: RawPaymentMethod) -> String {
        switch method {
        case .creditCardVisa:
            return "creditcard.fill"
        case .applePay:
            return "apple.logo"
        default:
            return "creditcard"
        }
    }
}
```

### Custom Checkout Flow

```swift
// Extend CheckoutViewController
class CustomCheckoutViewController: CheckoutViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add custom branding
        view.backgroundColor = .customBackground
        navigationItem.title = "Custom Checkout"
    }
}
```

## Troubleshooting

### Payment Method Not Available

```swift
// Check project configuration
let methods = project.availablePaymentMethods
print("Available: \(methods)")

// Check provider configuration
if methods.isEmpty {
    // Contact Snabble to enable payment methods
}
```

### Apple Pay Not Working

```swift
// Check entitlements
// Ensure "Apple Pay" capability is enabled in Xcode

// Check merchant ID
// Verify merchant ID matches Apple Developer account

// Check certificate
// Ensure Apple Pay certificate is valid
```

### Datatrans Integration Issues

```swift
// Ensure URL scheme is configured
// Info.plist must contain URL scheme

// Verify initialization
DatatransFactory.initialize(urlScheme: "myapp://")

// Check Datatrans SDK version
print(DatatransSDK.version)
```

## See Also

- [SnabbleCore](../Core/README.md) - Checkout process
- [SnabbleScanAndGo](../ScanAndGo/README.md) - Shopping flow
- [SnabbleTheme](../Theme/README.md) - Payment method UI assets
- [SDK Architecture Guide](../documentation/SDK-Architecture.md)
