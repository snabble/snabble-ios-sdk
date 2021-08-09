// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {

  public enum Snabble {
    /// Enter discount
    public static var addDiscount: String { return L10n.tr("SnabbleLocalizable", "Snabble.addDiscount") }
    /// Ask for permission
    public static var askForPermission: String { return L10n.tr("SnabbleLocalizable", "Snabble.askForPermission") }
    /// Cancel
    public static var cancel: String { return L10n.tr("SnabbleLocalizable", "Snabble.Cancel") }
    /// Delete
    public static var delete: String { return L10n.tr("SnabbleLocalizable", "Snabble.Delete") }
    /// Done
    public static var done: String { return L10n.tr("SnabbleLocalizable", "Snabble.Done") }
    /// Edit
    public static var edit: String { return L10n.tr("SnabbleLocalizable", "Snabble.Edit") }
    /// Go to settings
    public static var goToSettings: String { return L10n.tr("SnabbleLocalizable", "Snabble.goToSettings") }
    /// Loading product data…
    public static var loadingProductInformation: String { return L10n.tr("SnabbleLocalizable", "Snabble.loadingProductInformation") }
    /// Connection error
    public static var networkError: String { return L10n.tr("SnabbleLocalizable", "Snabble.networkError") }
    /// No
    public static var no: String { return L10n.tr("SnabbleLocalizable", "Snabble.No") }
    /// no discount
    public static var noDiscount: String { return L10n.tr("SnabbleLocalizable", "Snabble.noDiscount") }
    /// OK
    public static var ok: String { return L10n.tr("SnabbleLocalizable", "Snabble.OK") }
    /// Please wait…
    public static var pleaseWait: String { return L10n.tr("SnabbleLocalizable", "Snabble.pleaseWait") }
    /// Remove
    public static var remove: String { return L10n.tr("SnabbleLocalizable", "Snabble.remove") }
    /// Save
    public static var save: String { return L10n.tr("SnabbleLocalizable", "Snabble.Save") }
    /// Settings
    public static var settings: String { return L10n.tr("SnabbleLocalizable", "Snabble.Settings") }
    /// Undo
    public static var undo: String { return L10n.tr("SnabbleLocalizable", "Snabble.undo") }
    /// Yes
    public static var yes: String { return L10n.tr("SnabbleLocalizable", "Snabble.Yes") }
    public enum Biometry {
      /// Enter code
      public static var enterCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.enterCode") }
      /// Face ID
      public static var faceId: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.FaceId") }
      /// %@ is locked. Please enter your code in the lock screen to re-activate it.
      public static func locked(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.locked", String(describing: p1))
      }
      /// Touch ID
      public static var touchId: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.TouchId") }
      public enum Alert {
        /// Not now
        public static var laterButton: String { return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.Alert.laterButton") }
        /// Do you want to protect online payments with %@?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.Alert.message", String(describing: p1))
        }
        /// Activate %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Biometry.Alert.title", String(describing: p1))
        }
      }
    }
    public enum Cc {
      /// Card number
      public static var cardNumber: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.cardNumber") }
      /// Your credit card data is only stored in encrypted form and therefore cannot be edited.
      public static var editingHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.editingHint") }
      /// Unfortunately you can't add credit cards at this time.
      public static var noEntryPossible: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.noEntryPossible") }
      /// Valid until
      public static var validUntil: String { return L10n.tr("SnabbleLocalizable", "Snabble.CC.validUntil") }
      public enum _3dsecureHint {
        /// In order to verify your credit card, you will be redirected to your bank after entering your data. There you will be asked to approve a payment of € 1.00 to %@. The amount will be credited to you immediately after your approval.
        public static func retailer(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.CC.3dsecureHint.retailer", String(describing: p1))
        }
        /// In order to verify your credit card, you will be redirected to your bank after entering your data. There you will be asked to approve a payment of %@ to %@. The amount will be credited to you immediately after your approval.
        public static func retailerWithPrice(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.CC.3dsecureHint.retailerWithPrice", String(describing: p1), String(describing: p2))
        }
      }
    }
    public enum Checkout {
      /// Finished!
      public static var done: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.done") }
      /// An error has occurred
      public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.error") }
      /// Checkout-ID
      public static var id: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.ID") }
      /// Pay at cash register
      public static var payAtCashRegister: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.payAtCashRegister") }
      /// Pay
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.title") }
      /// Verifying
      public static var verifying: String { return L10n.tr("SnabbleLocalizable", "Snabble.Checkout.verifying") }
    }
    public enum CreditCard {
      /// Pay now using Credit card
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.CreditCard.payNow") }
    }
    public enum Hints {
      /// Well done! Please make things easy for the cashier and don't store your products in closed bags. Thank you!
      public static var closedBags: String { return L10n.tr("SnabbleLocalizable", "Snabble.Hints.closedBags") }
      /// Continue scanning
      public static var continueScanning: String { return L10n.tr("SnabbleLocalizable", "Snabble.Hints.continueScanning") }
      /// Info from %@
      public static func title(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Hints.title", String(describing: p1))
      }
    }
    public enum Keyguard {
      /// That's how we make sure that only you have access to this payment method
      public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Keyguard.message") }
      /// You need to secure your smartphone with a screen lock to add this payment method.
      public static var requireScreenLock: String { return L10n.tr("SnabbleLocalizable", "Snabble.Keyguard.requireScreenLock") }
      /// Please unlock your device
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Keyguard.title") }
    }
    public enum Payment {
      /// Payment process was cancelled
      public static var aborted: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.aborted") }
      /// Add payment method
      public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.add") }
      /// Transfer payment credentials to the app?
      public static var addPaymentOrigin: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.addPaymentOrigin") }
      /// Back to cart
      public static var backToCart: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.backToCart") }
      /// Back to start page
      public static var backToHome: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.backToHome") }
      /// Confirm purchase
      public static var confirm: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.confirm") }
      /// Credit card
      public static var creditCard: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.CreditCard") }
      /// Error creating the payment process
      public static var errorStarting: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.errorStarting") }
      /// Unfortunately, this purchase can't be made using the app.
      public static var noMethodAvailable: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.noMethodAvailable") }
      /// You are currently offline and some payment methods may not be available
      public static var offlineHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.offlineHint") }
      /// Cash desk
      public static var payAtCashDesk: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payAtCashDesk") }
      /// Card at EC terminal
      public static var payAtSCO: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payAtSCO") }
      /// with Customer Card
      public static var payUsingCustomerCard: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payUsingCustomerCard") }
      /// via Invoice
      public static var payViaInvoice: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.payViaInvoice") }
      /// Show this code at a Snabble monitor or to a cashier to confirm your purchase.
      public static var presentCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.presentCode") }
      /// Thank you for shopping
      public static var success: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.success") }
      /// Usable at: %@
      public static func usableAt(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Payment.usableAt", String(describing: p1))
      }
      /// Waiting for confirmation
      public static var waiting: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.waiting") }
      public enum CreditCard {
        /// There was an error processing your credit card
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.CreditCard.error") }
        /// Expires: %@
        public static func expireDate(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Payment.CreditCard.expireDate", String(describing: p1))
        }
      }
      public enum PostFinanceCard {
        /// There was an error processing your postfinance card
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.PostFinanceCard.error") }
      }
      public enum Sepa {
        /// Note: In order to protect you and our merchants against misuse, the merchant will have your bank card shown on your first payment by SEPA direct debit.
        public static var hint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.hint") }
        /// IBAN
        public static var iban: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.IBAN") }
        /// Please enter a valid IBAN.
        public static var invalidIBAN: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.InvalidIBAN") }
        /// Please enter a valid name.
        public static var invalidName: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.InvalidName") }
        /// Country code cannot be empty.
        public static var missingCountry: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.missingCountry") }
        /// Name
        public static var name: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.Name") }
        /// SEPA direct debit
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.SEPA.Title") }
      }
      public enum Twint {
        /// There was an error processing your TWINT account
        public static var error: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.Twint.error") }
      }
      public enum CancelError {
        /// Payment cannot be cancelled at this time.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.cancelError.message") }
        /// Error cancelling payment
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.cancelError.title") }
      }
      public enum Delete {
        /// Are you sure you want to remove this payment method?
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.delete.message") }
      }
      public enum EmptyState {
        /// Add payment method
        public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.emptyState.add") }
        /// You don't have any payment methods added yet.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.Payment.emptyState.message") }
      }
    }
    public enum PaymentCard {
      /// Your card data is only stored in encrypted form and therefore cannot be edited.
      public static var editingHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentCard.editingHint") }
    }
    public enum PaymentError {
      /// An error has occurred
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentError.title") }
      /// Try again
      public static var tryAgain: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentError.tryAgain") }
    }
    public enum PaymentMethods {
      /// Add payment method
      public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.add") }
      /// Which payment method to add?
      public static var choose: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.choose") }
      /// For all retailers
      public static var forAllRetailers: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.forAllRetailers") }
      /// For specific retailer
      public static var forSingleRetailer: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.forSingleRetailer") }
      /// No Code Protection
      public static var noDeviceCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.noDeviceCode") }
      /// Payment Methods
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.title") }
      public enum NoCodeAlert {
        /// Your iPhone isn't protected by a code or Touch ID/Face ID. For your own safety, please assign a code before storing your payment information.
        public static var biometry: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.noCodeAlert.biometry") }
        /// Your iPhone isn't protected by a code. For your own safety, please assign a code before storing your payment information.
        public static var noBiometry: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentMethods.noCodeAlert.noBiometry") }
      }
    }
    public enum PaymentSelection {
      /// Add now
      public static var addNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.addNow") }
      /// How would you like to pay %@?
      public static func howToPay(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.howToPay", String(describing: p1))
      }
      /// Pay %@ now
      public static func payNow(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.payNow", String(describing: p1))
      }
      /// Payment
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentSelection.title") }
    }
    public enum PaymentStatus {
      /// Locating you in the checkout area
      public static var step1: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.step1") }
      /// Processing your purchase
      public static var step2: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.step2") }
      /// Processing your payment
      public static var step3: String { return L10n.tr("SnabbleLocalizable", "Snabble.PaymentStatus.step3") }
    }
    public enum PostFinanceCard {
      /// Pay now using PostFinance Card
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.PostFinanceCard.payNow") }
    }
    public enum QRCode {
      /// Code %1$d of %2$d
      public static func codeXofY(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.codeXofY", p1, p2)
      }
      /// Done
      public static var didPay: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.didPay") }
      /// Please show QR code at the cash desk
      public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.message") }
      /// Show code %1$d of %2$d
      public static func nextCode(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.nextCode", p1, p2)
      }
      /// The exact price will be calculated by the register and may differ from the one shown here.
      public static var priceMayDiffer: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.priceMayDiffer") }
      /// Please show these %d codes at the register, one after the other
      public static func showTheseCodes(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.showTheseCodes", p1)
      }
      /// Please show this code at the register
      public static var showThisCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.showThisCode") }
      /// Pay at cash desk
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.title") }
      /// Total: 
      public static var total: String { return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.total") }
      public enum Entry {
        /// Code: %d
        public static func title(_ p1: Int) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.QRCode.entry.title", p1)
        }
      }
    }
    public enum Receipts {
      /// (loading)
      public static var loading: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.loading") }
      /// No Receipts found
      public static var noReceipts: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.noReceipts") }
      /// o'clock
      public static var oClock: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.oClock") }
      /// Receipts
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Receipts.title") }
    }
    public enum Sepa {
      /// Your SEPA data is only stored in encrypted form and therefore cannot be edited.
      public static var editingHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.editingHint") }
      /// Error encrypting data
      public static var encryptionError: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.encryptionError") }
      /// I agree
      public static var iAgree: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.iAgree") }
      /// SEPA direct debit mandate
      public static var mandate: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.mandate") }
      /// Pay now using SEPA
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.payNow") }
      /// Please enter the name from the card to save it for future payments.
      public static var scoTransferHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.scoTransferHint") }
      public enum IbanTransferAlert {
        /// Would you like to save this account information (IBAN: %@) for future purchases?
        public static func message(_ p1: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.ibanTransferAlert.message", String(describing: p1))
        }
        /// Save payment data
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.SEPA.ibanTransferAlert.title") }
      }
    }
    public enum Scanner {
      /// Add %@ as-is
      public static func addCodeAsIs(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.addCodeAsIs", String(describing: p1))
      }
      /// Add to cart
      public static var addToCart: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.addToCart") }
      /// Scanner stopped. Tap anywhere on the screen to continue.
      public static var batterySaverHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.batterySaverHint") }
      /// Added coupon “%@”
      public static func couponAdded(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.couponAdded", String(describing: p1))
      }
      /// Each deposit slip can only be scanned once.
      public static var duplicateDepositScanned: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.duplicateDepositScanned") }
      /// Enter code
      public static var enterBarcode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.enterBarcode") }
      /// Enter\nbarcode
      public static var enterCodeButton: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.enterCodeButton") }
      /// Scan your first product. Place the barcode in front of your camera.
      public static var firstScan: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.firstScan") }
      /// Cart: %@
      public static func goToCart(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.goToCart", String(describing: p1))
      }
      /// Scan product barcodes to add them to your shopping cart.
      public static var introText: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.introText") }
      /// You've entered a discounted price for your last item. Please note that an employee will check your purchase.
      public static var manualCouponAdded: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.manualCouponAdded") }
      /// Don't forget!
      public static var multiPack: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.multiPack") }
      /// Could not retrieve product data. Please check your internet connection.
      public static var networkError: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.networkError") }
      /// Product not found
      public static var noMatchesFound: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.noMatchesFound") }
      /// + %@ deposit
      public static func plusDeposit(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.plusDeposit", String(describing: p1))
      }
      /// Your age will be checked once at the time of payment.
      public static var scannedAgeRestrictedProduct: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.scannedAgeRestrictedProduct") }
      /// Please weigh the product, then scan the barcode from the sticker
      public static var scannedShelfCode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.scannedShelfCode") }
      /// Scan Barcode
      public static var scanningTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.scanningTitle") }
      /// Could not retrieve product data.
      public static var serverError: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.serverError") }
      /// Start scanner
      public static var start: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.start") }
      /// Scanner
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.title") }
      /// Torch
      public static var torchButton: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.torchButton") }
      /// No price information available for this product.
      public static var unknownBarcode: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.unknownBarcode") }
      /// Update cart
      public static var updateCart: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.updateCart") }
      public enum BundleDialog {
        /// Choose package
        public static var headline: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.BundleDialog.headline") }
      }
      public enum Camera {
        /// Camera access denied
        public static var accessDenied: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Camera.accessDenied") }
        /// Sorry, we'll need to access your camera to scan barcodes. Please allow this in the settings and return here.
        public static var allowAccess: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.Camera.allowAccess") }
      }
      public enum GoToCart {
        /// Cart
        public static var empty: String { return L10n.tr("SnabbleLocalizable", "Snabble.Scanner.goToCart.empty") }
      }
    }
    public enum ShoppingCart {
      /// Shopping Cart
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingCart.title") }
    }
    public enum ShoppingList {
      /// %@ saved
      public static func added(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.added", String(describing: p1))
      }
      /// %@ deleted
      public static func itemDeleted(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ItemDeleted", String(describing: p1))
      }
      /// Unknown product
      public static var notFound: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.notFound") }
      /// Search or enter directly
      public static var searchHint: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.searchHint") }
      /// Shopping list
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.title") }
      public enum CreateList {
        /// Create shopping list
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.CreateList.title") }
      }
      public enum EditList {
        /// Delete
        public static var delete: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.EditList.delete") }
        /// Save
        public static var save: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.EditList.save") }
        /// Edit shopping list
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.EditList.title") }
      }
      public enum ItemDeleted {
        /// Undo
        public static var undo: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ItemDeleted.Undo") }
      }
      public enum ListDeleted {
        /// Shopping list deleted
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListDeleted.title") }
        /// Undo
        public static var undo: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListDeleted.undo") }
      }
      public enum ListEmpty {
        /// Add product
        public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListEmpty.add") }
        /// Your shopping list is empty.
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.ListEmpty.title") }
      }
      public enum NoLists {
        /// Create shopping list
        public static var add: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.NoLists.add") }
        /// You have no shopping lists yet.
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.NoLists.title") }
      }
      public enum Voice {
        /// and
        public static var connectingWord: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.Voice.connectingWord") }
        /// Did you want to add several things to your shopping list? Then combine the individual entries with “and”, like this: Tissues and pasta and yeast
        public static var details: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.Voice.details") }
        /// Hint
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingList.Voice.title") }
      }
    }
    public enum ShoppingLists {
      /// Shopping lists
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ShoppingLists.title") }
    }
    public enum Shoppingcart {
      /// Product removed
      public static var articleRemoved: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.articleRemoved") }
      /// Buy %1$d products for %2$@
      public static func buyProducts(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.buyProducts", p1, String(describing: p2))
      }
      /// Coupon
      public static var coupon: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.coupon") }
      /// Coupons
      public static var coupons: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.coupons") }
      /// Deposit
      public static var deposit: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.deposit") }
      /// Discounts
      public static var discounts: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.discounts") }
      /// Free gift
      public static var giveaway: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.giveaway") }
      /// How would you like to pay?
      public static var howToPay: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.howToPay") }
      /// incl. deposit
      public static var includesDeposit: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.includesDeposit") }
      /// Not yet entered
      public static var noPaymentData: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.noPaymentData") }
      /// Not available for this purchase
      public static var notForThisPurchase: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.notForThisPurchase") }
      /// Not supported by this retailer
      public static var notForVendor: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.notForVendor") }
      /// %d products
      public static func numberOfItems(_ p1: Int) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.numberOfItems", p1)
      }
      /// Really remove %@?
      public static func removeItem(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.removeItem", String(describing: p1))
      }
      /// Really remove all products from your shopping cart?
      public static var removeItems: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.removeItems") }
      public enum BuyProducts {
        /// Pay now
        public static var now: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.buyProducts.now") }
        /// Buy %1$d product for %2$@
        public static func one(_ p1: Int, _ p2: Any) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.buyProducts.one", p1, String(describing: p2))
        }
      }
      public enum EmptyState {
        /// Scan now
        public static var buttonTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.buttonTitle") }
        /// Visit a store that supports Snabble and scan the barcodes of products you wish to purchase.
        public static var description: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.description") }
        /// Start new shopping trip
        public static var restartButtonTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.restartButtonTitle") }
        /// Restore previous cart
        public static var restoreButtonTitle: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.restoreButtonTitle") }
        /// Your shopping cart is empty
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.emptyState.title") }
      }
      public enum NumberOfItems {
        /// %d product
        public static func one(_ p1: Int) -> String {
          return L10n.tr("SnabbleLocalizable", "Snabble.Shoppingcart.numberOfItems.one", p1)
        }
      }
    }
    public enum Twint {
      /// Pay now using TWINT
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.TWINT.payNow") }
    }
    public enum Taxation {
      /// Will you be eating here or is this to go?
      public static var consumeWhere: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.consumeWhere") }
      /// Please choose
      public static var pleaseChoose: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.pleaseChoose") }
      public enum Consume {
        /// Eat here
        public static var inhouse: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.consume.inhouse") }
        /// Take with me
        public static var takeaway: String { return L10n.tr("SnabbleLocalizable", "Snabble.Taxation.consume.takeaway") }
      }
    }
    public enum AgeVerification {
      /// To purchase certain products like alcoholic beverages, verifying your age is required. Enter the 7-digit Number from the back side of your ID card.
      public static var explanation: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.explanation") }
      /// 7 Digits
      public static var placeholder: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.placeholder") }
      /// Age verification
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.title") }
      public enum Failed {
        /// Some products in your cart have an age restriction, unfortunately you can't purchase them.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.failed.message") }
        /// Age restriction
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.failed.title") }
      }
      public enum Pending {
        /// Some products in your cart have an age restriction. Please verify your age before continuing.
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.pending.message") }
        /// Age verification required
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.ageVerification.pending.title") }
      }
    }
    public enum InvalidDepositVoucher {
      /// Deposit return vouchers can be redeemed only once.
      public static var errorMsg: String { return L10n.tr("SnabbleLocalizable", "Snabble.invalidDepositVoucher.errorMsg") }
    }
    public enum LimitsAlert {
      /// With a total of more than %@, checkout using the app is unfortunately no longer possible.
      public static func checkoutNotAvailable(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.limitsAlert.checkoutNotAvailable", String(describing: p1))
      }
      /// With a total of more than %@, not all payment methods are available.
      public static func notAllMethodsAvailable(_ p1: Any) -> String {
        return L10n.tr("SnabbleLocalizable", "Snabble.limitsAlert.notAllMethodsAvailable", String(describing: p1))
      }
      /// Note
      public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.limitsAlert.title") }
    }
    public enum NotForSale {
      public enum ErrorMsg {
        /// This product cannot be paid for using the app, please pay for it at the cashier.
        public static var scan: String { return L10n.tr("SnabbleLocalizable", "Snabble.notForSale.errorMsg.scan") }
      }
    }
    public enum Paydirekt {
      /// Delete method
      public static var deleteAuthorization: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.deleteAuthorization") }
      /// Go to paydirekt.de
      public static var gotoWebsite: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.gotoWebsite") }
      /// Pay now using paydirekt
      public static var payNow: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.payNow") }
      /// You've successfully authorized Snabble for paydirekt. To remove this authorization, you need to log in to your paydirekt account. If you do not want to use this payment method anymore, you can remove it here.
      public static var savedAuthorization: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.savedAuthorization") }
      public enum AuthorizationFailed {
        /// Please try again later
        public static var message: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.authorizationFailed.message") }
        /// Authorization failed
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.paydirekt.authorizationFailed.title") }
      }
    }
    public enum SaleStop {
      /// These products cannot be paid for using the app, please pay for them at the cashier:
      public static var errorMsg: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg") }
      public enum ErrorMsg {
        /// This product cannot be paid for using the app, please pay for it at the cashier:
        public static var one: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg.one") }
        /// This product cannot be paid for using the app, please pay for it at the cashier.
        public static var scan: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg.scan") }
        /// Sorry
        public static var title: String { return L10n.tr("SnabbleLocalizable", "Snabble.saleStop.errorMsg.title") }
      }
    }
  }

  public enum Release {
    public enum Safety {
      /// Please remove the bottle's security device (if present) at the designated station at the exit.
      public static var `catch`: String { return L10n.tr("SnabbleLocalizable", "release.safety.catch") }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = SnabbleAPI.l10n(key, table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
