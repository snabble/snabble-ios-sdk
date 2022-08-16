// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Snabble {
    /// Enter discount
    public static var addDiscount: String { return L10n.tr("SnabbleLocalizable", "Snabble.addDiscount", fallback: "Enter discount") }
    /// Ask for permission
    public static var askForPermission: String { return L10n.tr("SnabbleLocalizable", "Snabble.askForPermission", fallback: "Ask for permission") }
    /// ********* Snabble *********
    public static var cancel: String { return L10n.tr("SnabbleLocalizable", "Snabble.Cancel", fallback: "Cancel") }
    /// Delete
    public static var delete: String { return L10n.tr("SnabbleLocalizable", "Snabble.Delete", fallback: "Delete") }
    /// Done
    public static var done: String { return L10n.tr("SnabbleLocalizable", "Snabble.Done", fallback: "Done") }
    /// Edit
    public static var edit: String { return L10n.tr("SnabbleLocalizable", "Snabble.Edit", fallback: "Edit") }
    /// Go to settings
    public static var goToSettings: String { return L10n.tr("SnabbleLocalizable", "Snabble.goToSettings", fallback: "Go to settings") }
    /// Loading product data…
    public static var loadingProductInformation: String { return L10n.tr("SnabbleLocalizable", "Snabble.loadingProductInformation", fallback: "Loading product data…") }
    /// Connection error
    public static var networkError: String { return L10n.tr("SnabbleLocalizable", "Snabble.networkError", fallback: "Connection error") }
    /// No
    public static var no: String { return L10n.tr("SnabbleLocalizable", "Snabble.No", fallback: "No") }
    /// no discount
    public static var noDiscount: String { return L10n.tr("SnabbleLocalizable", "Snabble.noDiscount", fallback: "no discount") }
    /// OK
    public static var ok: String { return L10n.tr("SnabbleLocalizable", "Snabble.OK", fallback: "OK") }
    /// Please wait…
    public static var pleaseWait: String { return L10n.tr("SnabbleLocalizable", "Snabble.pleaseWait", fallback: "Please wait…") }
    /// Remove
    public static var remove: String { return L10n.tr("SnabbleLocalizable", "Snabble.remove", fallback: "Remove") }
    /// Save
    public static var save: String { return L10n.tr("SnabbleLocalizable", "Snabble.Save", fallback: "Save") }
    /// Settings
    public static var settings: String { return L10n.tr("SnabbleLocalizable", "Snabble.Settings", fallback: "Settings") }
    /// Undo
    public static var undo: String { return L10n.tr("SnabbleLocalizable", "Snabble.undo", fallback: "Undo") }
    /// Yes
    public static var yes: String { return L10n.tr("SnabbleLocalizable", "Snabble.Yes", fallback: "Yes") }
    public enum Biometry {
      /// Enter code
      public static var enterCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.enterCode", fallback: "Enter code") }
      /// Face ID
      public static var faceId: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.FaceId", fallback: "Face ID") }
      /// %@ is locked. Please enter your code in the lock screen to re-activate it.
      public static func locked(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.locked", String(describing: p1), fallback: "%@ is locked. Please enter your code in the lock screen to re-activate it.")
      }
      /// ********* iOS Biometry *********, iOS only, this is used for the iOS-specific biometry settings views
      public static var touchId: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.TouchId", fallback: "Touch ID") }
      public enum Alert {
        /// Not now
        public static var laterButton: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.Alert.laterButton", fallback: "Not now") }
        /// Do you want to protect online payments with %@?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.Alert.message", String(describing: p1), fallback: "Do you want to protect online payments with %@?")
        }
        /// Activate %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.Alert.title", String(describing: p1), fallback: "Activate %@?")
        }
      }
    }
    public enum Cc {
      /// Card number
      public static var cardNumber: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.cardNumber", fallback: "Card number") }
      /// Your credit card data is only stored in encrypted form and therefore cannot be edited.
      public static var editingHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.editingHint", fallback: "Your credit card data is only stored in encrypted form and therefore cannot be edited.") }
      /// Unfortunately you can't add credit cards at this time.
      public static var noEntryPossible: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.noEntryPossible", fallback: "Unfortunately you can't add credit cards at this time.") }
      /// Valid until
      public static var validUntil: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.validUntil", fallback: "Valid until") }
      public enum _3dsecureHint {
        /// Enter your data here. We will then forward you to your bank to confirm your details. We reserve 1 € (for %@) and book the money back immediately.
        public static func retailer(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.CC.3dsecureHint.retailer", String(describing: p1), fallback: "Enter your data here. We will then forward you to your bank to confirm your details. We reserve 1 € (for %@) and book the money back immediately.")
        }
        /// Enter your data here. We will then forward you to your bank to confirm your details. We reserve %@ (for %@) and book the money back immediately.
        public static func retailerWithPrice(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.CC.3dsecureHint.retailerWithPrice", String(describing: p1), String(describing: p2), fallback: "Enter your data here. We will then forward you to your bank to confirm your details. We reserve %@ (for %@) and book the money back immediately.")
        }
      }
    }
    public enum Checkout {
      /// Finished!
      public static var done: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.done", fallback: "Finished!") }
      /// An error has occurred
      public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.error", fallback: "An error has occurred") }
      /// Checkout-ID
      public static var id: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.ID", fallback: "Checkout-ID") }
      /// Pay at cash register
      public static var payAtCashRegister: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.payAtCashRegister", fallback: "Pay at cash register") }
      /// Pay
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.title", fallback: "Pay") }
      /// Verifying
      public static var verifying: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.verifying", fallback: "Verifying") }
    }
    public enum Coupon {
      /// Activate
      public static var activate: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupon.activate", fallback: "Activate") }
      /// Activated
      public static var activated: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupon.activated", fallback: "Activated") }
      /// Coupon expires in %@ minutes
      public static func countdown(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Coupon.countdown", String(describing: p1), fallback: "Coupon expires in %@ minutes")
      }
      /// This coupon is expired.
      public static var expired: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupon.expired", fallback: "This coupon is expired.") }
      /// Your coupon is now activated for you. Please scan the product in the shop and put it in your shopping cart to benefit from it.
      public static var explanation: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupon.explanation", fallback: "Your coupon is now activated for you. Please scan the product in the shop and put it in your shopping cart to benefit from it.") }
      /// valid indefinitely
      public static var validIndefinitely: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupon.validIndefinitely", fallback: "valid indefinitely") }
    }
    public enum Coupons {
      /// Already expired
      public static var expired: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.expired", fallback: "Already expired") }
      /// valid until %@
      public static func expiresAtDate(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.expiresAtDate", String(describing: p1), fallback: "valid until %@")
      }
      /// Plural format key: "%#@localized_format_key@"
      public static func expiresInDays(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.expiresInDays", p1, fallback: "Plural format key: \"%#@localized_format_key@\"")
      }
      /// Plural format key: "%#@localized_format_key@"
      public static func expiresInHours(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.expiresInHours", p1, fallback: "Plural format key: \"%#@localized_format_key@\"")
      }
      /// Plural format key: "%#@localized_format_key@"
      public static func expiresInMinutes(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.expiresInMinutes", p1, fallback: "Plural format key: \"%#@localized_format_key@\"")
      }
      /// Plural format key: "%#@localized_format_key@"
      public static func expiresInWeeks(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.expiresInWeeks", p1, fallback: "Plural format key: \"%#@localized_format_key@\"")
      }
      /// No Coupons available
      public static var `none`: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.none", fallback: "No Coupons available") }
      /// Coupons
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Coupons.title", fallback: "Coupons") }
    }
    public enum CreditCard {
      /// Pay now using Credit card
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.CreditCard.payNow", fallback: "Pay now using Credit card") }
    }
    public enum Hints {
      /// Well done! Please make things easy for the cashier and don't store your products in closed bags. Thank you!
      public static var closedBags: String { return L10n.tr("SnabbleLocalizable", "Snabble.Hints.closedBags", fallback: "Well done! Please make things easy for the cashier and don't store your products in closed bags. Thank you!") }
      /// Continue scanning
      public static var continueScanning: String { return L10n.tr("SnabbleLocalizable", "Snabble.Hints.continueScanning", fallback: "Continue scanning") }
      /// Info from %@
      public static func title(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Hints.title", String(describing: p1), fallback: "Info from %@")
      }
    }
    public enum Keyguard {
      /// That's how we make sure that only you have access to this payment method
      public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Keyguard.message", fallback: "That's how we make sure that only you have access to this payment method") }
      /// You need to secure your smartphone with a screen lock to add this payment method.
      public static var requireScreenLock: String { return L10n.tr("SnabbleLocalizable", "Snabble.Keyguard.requireScreenLock", fallback: "You need to secure your smartphone with a screen lock to add this payment method.") }
      /// SECTION: Android KeyStore
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Keyguard.title", fallback: "Please unlock your device") }
    }
    public enum Onboarding {
      /// Agree
      public static var accept: String { return L10n.tr("SnabbleLocalizable", "Snabble.Onboarding.accept", fallback: "Agree") }
      /// Using Snabble, you scan your purchase yourself and pay directly in the app. No queueing and without putting your purchase on the belt.
      public static var message1: String { return L10n.tr("SnabbleLocalizable", "Snabble.Onboarding.message1", fallback: "Using Snabble, you scan your purchase yourself and pay directly in the app. No queueing and without putting your purchase on the belt.") }
      /// Enter a participating store, start shopping and hold the barcode of an article in front of the camera. The rest is self-explanatory.
      public static var message2: String { return L10n.tr("SnabbleLocalizable", "Snabble.Onboarding.message2", fallback: "Enter a participating store, start shopping and hold the barcode of an article in front of the camera. The rest is self-explanatory.") }
      /// Please accept the terms of use and take note of the privacy policy.
      public static var message3: String { return L10n.tr("SnabbleLocalizable", "Snabble.Onboarding.message3", fallback: "Please accept the terms of use and take note of the privacy policy.") }
      /// Continue
      public static var next: String { return L10n.tr("SnabbleLocalizable", "Snabble.Onboarding.next", fallback: "Continue") }
      public enum Terms {
        /// Show
        public static var show: String { return L10n.tr("SnabbleLocalizable", "Snabble.Onboarding.Terms.show", fallback: "Show") }
        /// Terms of Use
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Onboarding.Terms.title", fallback: "Terms of Use") }
      }
    }
    public enum Payment {
      /// SECTION: SnabbleAndroid
      public static var aborted: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.aborted", fallback: "Payment process was cancelled") }
      /// Add payment method
      public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.add", fallback: "Add payment method") }
      /// Transfer payment credentials to the app?
      public static var addPaymentOrigin: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.addPaymentOrigin", fallback: "Transfer payment credentials to the app?") }
      /// Back to cart
      public static var backToCart: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.backToCart", fallback: "Back to cart") }
      /// Back to start page
      public static var backToHome: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.backToHome", fallback: "Back to start page") }
      /// Confirm purchase
      public static var confirm: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.confirm", fallback: "Confirm purchase") }
      /// Credit card
      public static var creditCard: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.CreditCard", fallback: "Credit card") }
      /// Error creating the payment process
      public static var errorStarting: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.errorStarting", fallback: "Error creating the payment process") }
      /// Unfortunately, this purchase can't be made using the app.
      public static var noMethodAvailable: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.noMethodAvailable", fallback: "Unfortunately, this purchase can't be made using the app.") }
      /// You are currently offline and some payment methods may not be available
      public static var offlineHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.offlineHint", fallback: "You are currently offline and some payment methods may not be available") }
      /// Pay at the cash desk
      public static var payAtCashDesk: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payAtCashDesk", fallback: "Pay at the cash desk") }
      /// Card at EC terminal
      public static var payAtSCO: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payAtSCO", fallback: "Card at EC terminal") }
      /// with Customer Card
      public static var payUsingCustomerCard: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payUsingCustomerCard", fallback: "with Customer Card") }
      /// via Invoice
      public static var payViaInvoice: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payViaInvoice", fallback: "via Invoice") }
      /// Show this code at a Snabble monitor or to a cashier to confirm your purchase.
      public static var presentCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.presentCode", fallback: "Show this code at a Snabble monitor or to a cashier to confirm your purchase.") }
      /// Purchase denied
      public static var rejected: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.rejected", fallback: "Purchase denied") }
      /// Your purchase was denied. Please check your cart and start the checkout again.
      public static var rejectedHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.rejectedHint", fallback: "Your purchase was denied. Please check your cart and start the checkout again.") }
      /// Thank you for shopping
      public static var success: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.success", fallback: "Thank you for shopping") }
      /// Usable at: %@
      public static func usableAt(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Payment.usableAt", String(describing: p1), fallback: "Usable at: %@")
      }
      /// Waiting for confirmation
      public static var waiting: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.waiting", fallback: "Waiting for confirmation") }
      public enum CreditCard {
        /// There was an error processing your credit card
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.CreditCard.error", fallback: "There was an error processing your credit card") }
        /// Expires: %@
        public static func expireDate(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Payment.CreditCard.expireDate", String(describing: p1), fallback: "Expires: %@")
        }
      }
      public enum Online {
        /// Your purchase must be confirmed by an employee.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.Online.message", fallback: "Your purchase must be confirmed by an employee.") }
      }
      public enum PostFinanceCard {
        /// There was an error processing your postfinance card
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.PostFinanceCard.error", fallback: "There was an error processing your postfinance card") }
      }
      public enum Sepa {
        /// Note: In order to protect you and our merchants against misuse, the merchant will have your bank card shown on your first payment by SEPA direct debit.
        public static var hint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.hint", fallback: "Note: In order to protect you and our merchants against misuse, the merchant will have your bank card shown on your first payment by SEPA direct debit.") }
        /// IBAN
        public static var iban: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.IBAN", fallback: "IBAN") }
        /// Please enter a valid IBAN.
        public static var invalidIBAN: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.InvalidIBAN", fallback: "Please enter a valid IBAN.") }
        /// Please enter a valid name.
        public static var invalidName: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.InvalidName", fallback: "Please enter a valid name.") }
        /// Country code cannot be empty.
        public static var missingCountry: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.missingCountry", fallback: "Country code cannot be empty.") }
        /// Name
        public static var name: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.Name", fallback: "Name") }
        /// ********* iOS SEPA and Creditcard Data *********, iOS only, this is used for the iOS-specific SEPA data entry and payment
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.Title", fallback: "SEPA direct debit") }
      }
      public enum Twint {
        /// There was an error processing your TWINT account
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.Twint.error", fallback: "There was an error processing your TWINT account") }
      }
      public enum CancelError {
        /// Payment cannot be cancelled at this time.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.cancelError.message", fallback: "Payment cannot be cancelled at this time.") }
        /// Error cancelling payment
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.cancelError.title", fallback: "Error cancelling payment") }
      }
      public enum Delete {
        /// Are you sure you want to remove this payment method?
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.delete.message", fallback: "Are you sure you want to remove this payment method?") }
      }
      public enum EmptyState {
        /// Add payment method
        public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.emptyState.add", fallback: "Add payment method") }
        /// You don't have any payment methods added yet.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.emptyState.message", fallback: "You don't have any payment methods added yet.") }
      }
    }
    public enum PaymentCard {
      /// Your card data is only stored in encrypted form and therefore cannot be edited.
      public static var editingHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentCard.editingHint", fallback: "Your card data is only stored in encrypted form and therefore cannot be edited.") }
    }
    public enum PaymentContinuation {
      /// Continuing the payment
      public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentContinuation.message", fallback: "Continuing the payment") }
    }
    public enum PaymentError {
      /// An error has occurred
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentError.title", fallback: "An error has occurred") }
      /// Try again
      public static var tryAgain: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentError.tryAgain", fallback: "Try again") }
    }
    public enum PaymentMethods {
      /// Add payment method
      public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.add", fallback: "Add payment method") }
      /// Which payment method to add?
      public static var choose: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.choose", fallback: "Which payment method to add?") }
      /// For all retailers
      public static var forAllRetailers: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.forAllRetailers", fallback: "For all retailers") }
      /// For specific retailer
      public static var forSingleRetailer: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.forSingleRetailer", fallback: "For specific retailer") }
      /// No Code Protection
      public static var noDeviceCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.noDeviceCode", fallback: "No Code Protection") }
      /// ********* iOS Payment Methods *********
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.title", fallback: "Payment Methods") }
      public enum NoCodeAlert {
        /// Your iPhone isn't protected by a code or Touch ID/Face ID. For your own safety, please assign a code before storing your payment information.
        public static var biometry: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.noCodeAlert.biometry", fallback: "Your iPhone isn't protected by a code or Touch ID/Face ID. For your own safety, please assign a code before storing your payment information.") }
        /// Your iPhone isn't protected by a code. For your own safety, please assign a code before storing your payment information.
        public static var noBiometry: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.noCodeAlert.noBiometry", fallback: "Your iPhone isn't protected by a code. For your own safety, please assign a code before storing your payment information.") }
      }
    }
    public enum PaymentSelection {
      /// Add now
      public static var addNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.addNow", fallback: "Add now") }
      /// How would you like to pay %@?
      public static func howToPay(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.howToPay", String(describing: p1), fallback: "How would you like to pay %@?")
      }
      /// Pay %@ now
      public static func payNow(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.payNow", String(describing: p1), fallback: "Pay %@ now")
      }
      /// Payment
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.title", fallback: "Payment") }
    }
    public enum PaymentStatus {
      /// Back
      public static var back: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.back", fallback: "Back") }
      /// Close
      public static var close: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.close", fallback: "Close") }
      /// Locating you in the checkout area
      public static var step1: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.step1", fallback: "Locating you in the checkout area") }
      /// Processing your purchase
      public static var step2: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.step2", fallback: "Processing your purchase") }
      /// Processing your payment
      public static var step3: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.step3", fallback: "Processing your payment") }
      public enum AddDebitCard {
        /// Yes, save girocard in app
        public static var button: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.AddDebitCard.button", fallback: "Yes, save girocard in app") }
        /// Would you like to store your girocard data securely in the app so that you can pay for your next purchase by direct debit? You can leave your card in your wallet in the future.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.AddDebitCard.message", fallback: "Would you like to store your girocard data securely in the app so that you can pay for your next purchase by direct debit? You can leave your card in your wallet in the future.") }
      }
      public enum DebitCardAdded {
        /// We have successfully verified your card. You can now pay by SEPA direct debit. You can leave your girocard in your wallet in the future.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.DebitCardAdded.message", fallback: "We have successfully verified your card. You can now pay by SEPA direct debit. You can leave your girocard in your wallet in the future.") }
      }
      public enum ExitCode {
        /// The code is only valid for a short time.
        public static var openExitGateTimed: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.ExitCode.openExitGateTimed", fallback: "The code is only valid for a short time.") }
        /// Exit-Code
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.ExitCode.title", fallback: "Exit-Code") }
      }
      public enum Fulfillment {
        /// Fulfillment
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Fulfillment.title", fallback: "Fulfillment") }
      }
      public enum Payment {
        /// Your payment could not be processed. Try again or choose another payment method.
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Payment.error", fallback: "Your payment could not be processed. Try again or choose another payment method.") }
        /// Payment
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Payment.title", fallback: "Payment") }
        /// Try again
        public static var tryAgain: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Payment.tryAgain", fallback: "Try again") }
      }
      public enum Rating {
        /// Send
        public static var send: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Rating.send", fallback: "Send") }
        /// What was not good?
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Rating.title", fallback: "What was not good?") }
      }
      public enum Ratings {
        /// Thank you!
        public static var thanks: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Ratings.thanks", fallback: "Thank you!") }
        /// Did you like the purchase?
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Ratings.title", fallback: "Did you like the purchase?") }
      }
      public enum Receipt {
        /// Receipt
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Receipt.title", fallback: "Receipt") }
      }
      public enum Title {
        /// Unfortunately an error has occurred
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Title.error", fallback: "Unfortunately an error has occurred") }
        /// Your purchase is completing
        public static var inProgress: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Title.inProgress", fallback: "Your purchase is completing") }
        /// Thank you for your purchase!
        public static var success: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Title.success", fallback: "Thank you for your purchase!") }
      }
      public enum Tobacco {
        /// A problem has occurred with the distribution of cigarettes. Please inform a staff member.
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Tobacco.error", fallback: "A problem has occurred with the distribution of cigarettes. Please inform a staff member.") }
        /// Please remove your cigarettes.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Tobacco.message", fallback: "Please remove your cigarettes.") }
        /// Cigarette distribution
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.Tobacco.title", fallback: "Cigarette distribution") }
      }
    }
    public enum Payone {
      /// Card Number
      public static var cardNumber: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payone.cardNumber", fallback: "Card Number") }
      /// Card Security Code (CVV)
      public static var cvc: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payone.cvc", fallback: "Card Security Code (CVV)") }
      /// Expiry Month (MM)
      public static var expireMonth: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payone.expireMonth", fallback: "Expiry Month (MM)") }
      /// Expiry Year (YYYY)
      public static var expireYear: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payone.expireYear", fallback: "Expiry Year (YYYY)") }
      /// Please enter all required data.
      public static var incompleteForm: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payone.incompleteForm", fallback: "Please enter all required data.") }
      /// Last Name
      public static var lastname: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payone.Lastname", fallback: "Last Name") }
    }
    public enum PostFinanceCard {
      /// Pay now using PostFinance Card
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.PostFinanceCard.payNow", fallback: "Pay now using PostFinance Card") }
    }
    public enum QRCode {
      /// Code %1$d of %2$d
      public static func codeXofY(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.codeXofY", p1, p2, fallback: "Code %1$d of %2$d")
      }
      /// I paid at the cash register
      public static var didPay: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.didPay", fallback: "I paid at the cash register") }
      /// Please show QR code at the cash desk
      public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.message", fallback: "Please show QR code at the cash desk") }
      /// Show code %1$d of %2$d
      public static func nextCode(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.nextCode", p1, p2, fallback: "Show code %1$d of %2$d")
      }
      /// The exact price will be calculated by the register and may differ from the one shown here.
      public static var priceMayDiffer: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.priceMayDiffer", fallback: "The exact price will be calculated by the register and may differ from the one shown here.") }
      /// Please show these %d codes at the register, one after the other
      public static func showTheseCodes(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.showTheseCodes", p1, fallback: "Please show these %d codes at the register, one after the other")
      }
      /// Please show this code at the register
      public static var showThisCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.showThisCode", fallback: "Please show this code at the register") }
      /// Pay at cash desk
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.title", fallback: "Pay at cash desk") }
      /// Total: 
      public static var total: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.total", fallback: "Total: ") }
      public enum DidPayDialog {
        /// Back to QR-Code
        public static var cancel: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.DidPayDialog.cancel", fallback: "Back to QR-Code") }
        /// Did you pay at checkout so we can discard the cart?
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.DidPayDialog.message", fallback: "Did you pay at checkout so we can discard the cart?") }
        /// Yes, discard shopping cart
        public static var ok: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.DidPayDialog.ok", fallback: "Yes, discard shopping cart") }
      }
      public enum Entry {
        /// Code: %d
        public static func title(_ p1: Int) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.entry.title", p1, fallback: "Code: %d")
        }
      }
    }
    public enum Receipts {
      /// (loading)
      public static var loading: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.loading", fallback: "(loading)") }
      /// No Receipts found
      public static var noReceipts: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.noReceipts", fallback: "No Receipts found") }
      /// o'clock
      public static var oClock: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.oClock", fallback: "o'clock") }
      /// Receipts
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.title", fallback: "Receipts") }
    }
    public enum Sepa {
      /// Your SEPA data is only stored in encrypted form and therefore cannot be edited.
      public static var editingHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.editingHint", fallback: "Your SEPA data is only stored in encrypted form and therefore cannot be edited.") }
      /// Error encrypting data
      public static var encryptionError: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.encryptionError", fallback: "Error encrypting data") }
      /// I agree
      public static var iAgree: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.iAgree", fallback: "I agree") }
      /// SEPA direct debit mandate
      public static var mandate: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.mandate", fallback: "SEPA direct debit mandate") }
      /// Pay now using SEPA
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.payNow", fallback: "Pay now using SEPA") }
      /// Please enter the name from the card to save it for future payments.
      public static var scoTransferHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.scoTransferHint", fallback: "Please enter the name from the card to save it for future payments.") }
      public enum IbanTransferAlert {
        /// Would you like to save this account information (IBAN: %@) for future purchases?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.ibanTransferAlert.message", String(describing: p1), fallback: "Would you like to save this account information (IBAN: %@) for future purchases?")
        }
        /// Save payment data
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.ibanTransferAlert.title", fallback: "Save payment data") }
      }
    }
    public enum Scanner {
      /// Add %@ as-is
      public static func addCodeAsIs(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.addCodeAsIs", String(describing: p1), fallback: "Add %@ as-is")
      }
      /// Add to cart
      public static var addToCart: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.addToCart", fallback: "Add to cart") }
      /// Scanner stopped. Tap anywhere on the screen to continue.
      public static var batterySaverHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.batterySaverHint", fallback: "Scanner stopped. Tap anywhere on the screen to continue.") }
      /// Added coupon “%@”
      public static func couponAdded(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.couponAdded", String(describing: p1), fallback: "Added coupon “%@”")
      }
      /// Each deposit slip can only be scanned once.
      public static var duplicateDepositScanned: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.duplicateDepositScanned", fallback: "Each deposit slip can only be scanned once.") }
      /// Enter code
      public static var enterBarcode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.enterBarcode", fallback: "Enter code") }
      /// Enter
      /// barcode
      public static var enterCodeButton: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.enterCodeButton", fallback: "Enter\nbarcode") }
      /// Text der Snackbar die Angezeigt wird, wenn der Benutzer noch nie ein Produkt gescannt hat
      public static var firstScan: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.firstScan", fallback: "Scan your first product. Place the barcode in front of your camera.") }
      /// Cart: %@
      public static func goToCart(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.goToCart", String(describing: p1), fallback: "Cart: %@")
      }
      /// Scan product barcodes to add them to your shopping cart.
      public static var introText: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.introText", fallback: "Scan product barcodes to add them to your shopping cart.") }
      /// You've entered a discounted price for your last item. Please note that an employee will check your purchase.
      public static var manualCouponAdded: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.manualCouponAdded", fallback: "You've entered a discounted price for your last item. Please note that an employee will check your purchase.") }
      /// Don't forget!
      public static var multiPack: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.multiPack", fallback: "Don't forget!") }
      /// Could not retrieve product data. Please check your internet connection.
      public static var networkError: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.networkError", fallback: "Could not retrieve product data. Please check your internet connection.") }
      /// Product not found
      public static var noMatchesFound: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.noMatchesFound", fallback: "Product not found") }
      /// + %@ deposit
      public static func plusDeposit(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.plusDeposit", String(describing: p1), fallback: "+ %@ deposit")
      }
      /// Your age will be checked once at the time of payment.
      public static var scannedAgeRestrictedProduct: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.scannedAgeRestrictedProduct", fallback: "Your age will be checked once at the time of payment.") }
      /// Please weigh the product, then scan the barcode from the sticker
      public static var scannedShelfCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.scannedShelfCode", fallback: "Please weigh the product, then scan the barcode from the sticker") }
      /// Scan Barcode
      public static var scanningTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.scanningTitle", fallback: "Scan Barcode") }
      /// Could not retrieve product data.
      public static var serverError: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.serverError", fallback: "Could not retrieve product data.") }
      /// Start scanner
      public static var start: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.start", fallback: "Start scanner") }
      /// Scanner
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.title", fallback: "Scanner") }
      /// Torch
      public static var torchButton: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.torchButton", fallback: "Torch") }
      /// No price information available for this product.
      public static var unknownBarcode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.unknownBarcode", fallback: "No price information available for this product.") }
      /// Update cart
      public static var updateCart: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.updateCart", fallback: "Update cart") }
      public enum Accessibility {
        /// Hide hint permanently
        public static var actionHideHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.actionHideHint", fallback: "Hide hint permanently") }
        /// Understood
        public static var actionUnderstood: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.actionUnderstood", fallback: "Understood") }
        /// Please enter the quantity in %@
        public static func enterQuantity(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.enterQuantity", String(describing: p1), fallback: "Please enter the quantity in %@")
        }
        /// You are back in scanner
        public static var eventBackInScanner: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.eventBackInScanner", fallback: "You are back in scanner") }
        /// Barcode detected
        public static var eventBarcodeDetected: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.eventBarcodeDetected", fallback: "Barcode detected") }
        /// You reached the maximum count of items for the cart
        public static var eventMaxQuantityReached: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.eventMaxQuantityReached", fallback: "You reached the maximum count of items for the cart") }
        /// Example: 3 times Banana for 3$
        public static func eventQuantityUpdate(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.eventQuantityUpdate", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "%@ times %@ for %@")
        }
        /// You opened the scanner.
        public static var eventScannerOpened: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.eventScannerOpened", fallback: "You opened the scanner.") }
        /// There are %@ items for %@ in your cart.
        public static func hintCartContent(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.hintCartContent", String(describing: p1), String(describing: p2), fallback: "There are %@ items for %@ in your cart.")
        }
        /// Your cart is empty.
        public static var hintCartIsEmpty: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.hintCartIsEmpty", fallback: "Your cart is empty.") }
        /// In order to scan we need a permission from you.
        public static var hintPermission: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Accessibility.hintPermission", fallback: "In order to scan we need a permission from you.") }
      }
      public enum BundleDialog {
        /// Choose package
        public static var headline: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.BundleDialog.headline", fallback: "Choose package") }
      }
      public enum Camera {
        /// Camera access denied
        public static var accessDenied: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Camera.accessDenied", fallback: "Camera access denied") }
        /// Sorry, we'll need to access your camera to scan barcodes. Please allow this in the settings and return here.
        public static var allowAccess: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Camera.allowAccess", fallback: "Sorry, we'll need to access your camera to scan barcodes. Please allow this in the settings and return here.") }
      }
      public enum GoToCart {
        /// Cart
        public static var empty: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.goToCart.empty", fallback: "Cart") }
      }
    }
    public enum Shopping {
      /// Shopping
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shopping.title", fallback: "Shopping") }
    }
    public enum ShoppingCart {
      /// Shopping Cart
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingCart.title", fallback: "Shopping Cart") }
    }
    public enum ShoppingList {
      /// Hinweiß der angezeigt wird wenn ein Artikel der Einkaufsliste hinzugefügt wurde
      public static func added(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.added", String(describing: p1), fallback: "%@ saved")
      }
      /// Der Text wird angezeigt wenn man ein Element der Einkaufsliste wegwischt
      public static func itemDeleted(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ItemDeleted", String(describing: p1), fallback: "%@ deleted")
      }
      /// Hinweiß der angezeigt wird wenn ein Artikel nicht gefunden wurde
      public static var notFound: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.notFound", fallback: "Unknown product") }
      /// Der Hint der angezeigt wird wenn man einen Artikel per Suche hinzufügen möchte
      public static var searchHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.searchHint", fallback: "Search or enter directly") }
      /// Der Titel der übersichtsseite der Einkaufslisten
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.title", fallback: "Shopping List") }
      public enum CreateList {
        /// Der Titel des Dialogs zur Erzeugung einer neuen Einkaufsliste
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.CreateList.title", fallback: "Create shopping list") }
      }
      public enum EditList {
        /// Der Löschen-Knopf beim Editieren von Einkaufslisten
        public static var delete: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.EditList.delete", fallback: "Delete") }
        /// Der Speichern-Knopf beim Editieren von Einkaufslisten
        public static var save: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.EditList.save", fallback: "Save") }
        /// Der Titel des Popups zum bearbeiten von Einkaufslisten
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.EditList.title", fallback: "Edit shopping list") }
      }
      public enum ItemDeleted {
        /// Der Call-To-Action wenn man das löschen eines Elements der Einkaufsliste rückgänig machen möchte
        public static var undo: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ItemDeleted.Undo", fallback: "Undo") }
      }
      public enum ListDeleted {
        /// Der Inhalt der Snackbar wenn eine Einkaufsliste gelöscht wurde
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListDeleted.title", fallback: "Shopping list deleted") }
        /// Der Call-To-Action wenn eine Einkaufsliste wiederhergestellt werden soll
        public static var undo: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListDeleted.undo", fallback: "Undo") }
      }
      public enum ListEmpty {
        /// Der Call-To-Action beim Empty-State Text wenn der Einkaufszettel noch leer ist
        public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListEmpty.add", fallback: "Add product") }
        /// Empty-State Text wenn der Einkaufszettel noch leer ist
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListEmpty.title", fallback: "Your shopping list is empty.") }
      }
      public enum NoLists {
        /// Der Call-To-Action beim Empty-State Text wenn noch kein Einkaufszettel angelegt wurde
        public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.NoLists.add", fallback: "Create shopping list") }
        /// Der Empty-State wenn noch kein Einkaufszettel angelegt wurde
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.NoLists.title", fallback: "You have no shopping lists yet.") }
      }
      public enum Voice {
        /// Man soll verschiedene Artikel mit einem "und" in die Einkaufsliste legen können. Hier geht es nur um das Wort "und"
        public static var connectingWord: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.Voice.connectingWord", fallback: "and") }
        /// Hinweis der Eingeblendet wird wenn der Benutzer das erste mal vermutlich falsch mehrere Artikel zum Einkaufszettel ergänezen wollte
        public static var details: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.Voice.details", fallback: "Did you want to add several things to your shopping list? Then combine the individual entries with “and”, like this: Tissues and pasta and yeast") }
        /// Hinweis der Eingeblendet wird wenn der Benutzer das erste mal vermutlich falsch mehrere Artikel zum Einkaufszettel ergänezen wollte
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.Voice.title", fallback: "Hint") }
      }
    }
    public enum ShoppingLists {
      /// Der Titel der übersichtsseite der Einkaufslisten
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingLists.title", fallback: "Shopping lists") }
    }
    public enum Shoppingcart {
      /// Product removed
      public static var articleRemoved: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.articleRemoved", fallback: "Product removed") }
      /// Buy %1$d products for %2$@
      public static func buyProducts(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.buyProducts", p1, String(describing: p2), fallback: "Buy %1$d products for %2$@")
      }
      /// Coupon
      public static var coupon: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.coupon", fallback: "Coupon") }
      /// Coupons
      public static var coupons: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.coupons", fallback: "Coupons") }
      /// Deposit
      public static var deposit: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.deposit", fallback: "Deposit") }
      /// Discounts
      public static var discounts: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.discounts", fallback: "Discounts") }
      /// Free gift
      public static var giveaway: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.giveaway", fallback: "Free gift") }
      /// How would you like to pay?
      public static var howToPay: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.howToPay", fallback: "How would you like to pay?") }
      /// incl. deposit
      public static var includesDeposit: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.includesDeposit", fallback: "incl. deposit") }
      /// Add now
      public static var noPaymentData: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.noPaymentData", fallback: "Add now") }
      /// Not available for this purchase
      public static var notForThisPurchase: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.notForThisPurchase", fallback: "Not available for this purchase") }
      /// Not supported by this retailer
      public static var notForVendor: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.notForVendor", fallback: "Not supported by this retailer") }
      /// Plural format key: "%#@localized_format_key@"
      public static func numberOfItems(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.numberOfItems", p1, fallback: "Plural format key: \"%#@localized_format_key@\"")
      }
      /// Really remove %@?
      public static func removeItem(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.removeItem", String(describing: p1), fallback: "Really remove %@?")
      }
      /// Really remove all products from your shopping cart?
      public static var removeItems: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.removeItems", fallback: "Really remove all products from your shopping cart?") }
      public enum Accessibility {
        /// Add
        public static var actionAdd: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.actionAdd", fallback: "Add") }
        /// Delete
        public static var actionDelete: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.actionDelete", fallback: "Delete") }
        /// Use
        public static var actionUse: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.actionUse", fallback: "Use") }
        /// Ends with %@
        public static func cardEndsWith(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.cardEndsWith", String(describing: p1), fallback: "Ends with %@")
        }
        /// Close dialog
        public static var closeDialog: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.closeDialog", fallback: "Close dialog") }
        /// In cart
        public static var contextInCart: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.contextInCart", fallback: "In cart") }
        /// Decrease quantity
        public static var decreaseQuantity: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.decreaseQuantity", fallback: "Decrease quantity") }
        /// for %@
        public static func descriptionForPrice(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.descriptionForPrice", String(describing: p1), fallback: "for %@")
        }
        /// %@ times
        public static func descriptionQuantity(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.descriptionQuantity", String(describing: p1), fallback: "%@ times")
        }
        /// with discount
        public static var descriptionWithDiscount: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.descriptionWithDiscount", fallback: "with discount") }
        /// without discount
        public static var descriptionWithoutDiscount: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.descriptionWithoutDiscount", fallback: "without discount") }
        /// Increase quantity
        public static var increaseQuantity: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.increaseQuantity", fallback: "Increase quantity") }
        /// Payment method: %@
        public static func paymentMethod(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.paymentMethod", String(describing: p1), fallback: "Payment method: %@")
        }
        /// Quantity
        public static var quantity: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.quantity", fallback: "Quantity") }
        /// Selected
        public static var selected: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.Accessibility.selected", fallback: "Selected") }
      }
      public enum BuyProducts {
        /// Pay now
        public static var now: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.buyProducts.now", fallback: "Pay now") }
        /// Buy %1$d product for %2$@
        public static func one(_ p1: Int, _ p2: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.buyProducts.one", p1, String(describing: p2), fallback: "Buy %1$d product for %2$@")
        }
        /// Select payment method
        public static var selectPaymentMethod: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.buyProducts.selectPaymentMethod", fallback: "Select payment method") }
      }
      public enum EmptyState {
        /// Scan now
        public static var buttonTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.buttonTitle", fallback: "Scan now") }
        /// Visit a store that supports Snabble and scan the barcodes of products you wish to purchase.
        public static var description: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.description", fallback: "Visit a store that supports Snabble and scan the barcodes of products you wish to purchase.") }
        /// Start new shopping trip
        public static var restartButtonTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.restartButtonTitle", fallback: "Start new shopping trip") }
        /// Restore previous cart
        public static var restoreButtonTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.restoreButtonTitle", fallback: "Restore previous cart") }
        /// Your shopping cart is empty
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.title", fallback: "Your shopping cart is empty") }
      }
    }
    public enum Twint {
      /// Pay now using TWINT
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.TWINT.payNow", fallback: "Pay now using TWINT") }
    }
    public enum Taxation {
      /// Will you be eating here or is this to go?
      public static var consumeWhere: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.consumeWhere", fallback: "Will you be eating here or is this to go?") }
      /// Please choose
      public static var pleaseChoose: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.pleaseChoose", fallback: "Please choose") }
      public enum Consume {
        /// Eat here
        public static var inhouse: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.consume.inhouse", fallback: "Eat here") }
        /// Take with me
        public static var takeaway: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.consume.takeaway", fallback: "Take with me") }
      }
    }
    public enum Violations {
      /// A coupon is already redeemed and will be removed from cart
      public static var couponAlreadyVoided: String { return L10n.tr("SnabbleLocalizable", "Snabble.Violations.couponAlreadyVoided", fallback: "A coupon is already redeemed and will be removed from cart") }
      /// A coupon is currently not valid and will be removed from cart
      public static var couponCurrentlyNotValid: String { return L10n.tr("SnabbleLocalizable", "Snabble.Violations.couponCurrentlyNotValid", fallback: "A coupon is currently not valid and will be removed from cart") }
      /// A coupon is invalid and will be removed from cart
      public static var couponInvalid: String { return L10n.tr("SnabbleLocalizable", "Snabble.Violations.couponInvalid", fallback: "A coupon is invalid and will be removed from cart") }
      /// Invalid shopping cart
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Violations.title", fallback: "Invalid shopping cart") }
    }
    public enum AgeVerification {
      /// To purchase certain products like alcoholic beverages, verifying your age is required. Enter the 7-digit Number from the back side of your ID card.
      public static var explanation: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.explanation", fallback: "To purchase certain products like alcoholic beverages, verifying your age is required. Enter the 7-digit Number from the back side of your ID card.") }
      /// 7 Digits
      public static var placeholder: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.placeholder", fallback: "7 Digits") }
      /// ********* Age Verification *********
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.title", fallback: "Age verification") }
      public enum Failed {
        /// Some products in your cart have an age restriction, unfortunately you can't purchase them.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.failed.message", fallback: "Some products in your cart have an age restriction, unfortunately you can't purchase them.") }
        /// Age restriction
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.failed.title", fallback: "Age restriction") }
      }
      public enum Pending {
        /// Some products in your cart have an age restriction. Please verify your age before continuing.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.pending.message", fallback: "Some products in your cart have an age restriction. Please verify your age before continuing.") }
        /// Age verification required
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.pending.title", fallback: "Age verification required") }
      }
    }
    public enum InvalidDepositVoucher {
      /// Deposit return vouchers can be redeemed only once.
      public static var errorMsg: String { return L10n.tr("SnabbleLocalizable", "Snabble.invalidDepositVoucher.errorMsg", fallback: "Deposit return vouchers can be redeemed only once.") }
    }
    public enum LimitsAlert {
      /// With a total of more than %@, checkout using the app is unfortunately no longer possible.
      public static func checkoutNotAvailable(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.limitsAlert.checkoutNotAvailable", String(describing: p1), fallback: "With a total of more than %@, checkout using the app is unfortunately no longer possible.")
      }
      /// With a total of more than %@, not all payment methods are available.
      public static func notAllMethodsAvailable(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.limitsAlert.notAllMethodsAvailable", String(describing: p1), fallback: "With a total of more than %@, not all payment methods are available.")
      }
      /// Note
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.limitsAlert.title", fallback: "Note") }
    }
    public enum NotForSale {
      public enum ErrorMsg {
        /// This product cannot be paid for using the app, please pay for it at the cashier.
        public static var scan: String { return L10n.tr("SnabbleLocalizable", "Snabble.notForSale.errorMsg.scan", fallback: "This product cannot be paid for using the app, please pay for it at the cashier.") }
      }
    }
    public enum Paydirekt {
      /// Delete method
      public static var deleteAuthorization: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.deleteAuthorization", fallback: "Delete method") }
      /// Go to paydirekt.de
      public static var gotoWebsite: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.gotoWebsite", fallback: "Go to paydirekt.de") }
      /// Pay now using paydirekt
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.payNow", fallback: "Pay now using paydirekt") }
      /// You've successfully authorized Snabble for paydirekt. To remove this authorization, you need to log in to your paydirekt account. If you do not want to use this payment method anymore, you can remove it here.
      public static var savedAuthorization: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.savedAuthorization", fallback: "You've successfully authorized Snabble for paydirekt. To remove this authorization, you need to log in to your paydirekt account. If you do not want to use this payment method anymore, you can remove it here.") }
      /// paydirekt
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.title", fallback: "paydirekt") }
      public enum AuthorizationFailed {
        /// Please try again later
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.authorizationFailed.message", fallback: "Please try again later") }
        /// Authorization failed
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.authorizationFailed.title", fallback: "Authorization failed") }
      }
    }
    public enum SaleStop {
      /// These products cannot be paid for using the app, please pay for them at the cashier:
      public static var errorMsg: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg", fallback: "These products cannot be paid for using the app, please pay for them at the cashier:") }
      public enum ErrorMsg {
        /// This product cannot be paid for using the app, please pay for it at the cashier:
        public static var one: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg.one", fallback: "This product cannot be paid for using the app, please pay for it at the cashier:") }
        /// This product cannot be paid for using the app, please pay for it at the cashier.
        public static var scan: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg.scan", fallback: "This product cannot be paid for using the app, please pay for it at the cashier.") }
        /// Sorry
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg.title", fallback: "Sorry") }
      }
    }
  }
  public enum Release {
    public enum Safety {
      /// Please remove the bottle's security device (if present) at the designated station at the exit.
      public static var `catch`: String { return L10n.tr("SnabbleLocalizable", "release.safety.catch", fallback: "Please remove the bottle's security device (if present) at the designated station at the exit.") }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = SnabbleSDK.Snabble.l10n(key, table, value)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
