# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

### Added

### Removed
* AutoLayout-Helper Dependencies - Moved function in the SDK
* Public init for ShoppingCart

### Changed
* renamed ProductProvider functions by removing unnamed (underscore) arguments

### Updated
* groue/GRDB.swift 6.1.0 (was 6.0.0)
* devicekit/DeviceKit 5.0.0 (was 4.7.0)

## [0.23.0] - 2022-10-11

### Added
* Danger to automate common code review chores
* Package.swift
* Separate Swift packages (spm) for SnabbleCore, SnabbleUI and SnabbleDatatrans

### Removed
* icon-trash, icon-minus and icon-plus image from asset catalog
* CocoaPods support

### Changed
* Use systemNamed image for trash, minus and plus buttons
* Display trash button in all quantity views if quantity equals 1
* Only fire cart event on user interaction in shopping cart
* Repo name is now `snabble-ios-sdk`
* `SwiftBase32` replaced with `Base32`
* Example App `SnabbleSampleApp` uses Swift Package Manager
* All SDK resources (language files and images) moved from Snabble/UI to UI/Resources
* WidgetInformation init() is now public
* WidgetInformationView text font is subheadline, bigger spacing, horizontal center aligned

### Updated
* Datatrans 2.3.1 (was 2.2.0)

## [0.22.1] - 2022-09-22
### Changed
* update repository reference in podspec

## [0.22.0] - 2022-09-21
### Added
* `SwiftBase32` as dependency for Core 
* `AssetProviding` Protocol #APPS-442
* Missing translation `Snabble.Payment.Online.message` #APPS-444

### Changed
* colors lookup via `AssetProviding`

## [0.21.0] - 2022-08-10

### Changed
* incremeant deployment Target iOS 14.0
* `setCoupons` and `setShops` on project not index
* implement `Equatable` and `Hashable` to Project
* add `Hashable` to Coupon
* Coupons #APPS-297
* Added dynamic fonts to DatatransAliasViewController #APPS-231
* Refactored DatatransAliasViewController to programmatically written UI
* Fix for ScanMessageView and refactoring with ViewProvider pattern #APPS-339

### Added
* Extension UIStackView+Remove added
* Shop Distance Analytics #APPS-274

### Removed
* `Gutschein` handling
* `ColorCompability` dependency

## [0.20.0] - 2022-06-23

### Changed 
* Improved Check-In and Check-out logic #APPS-273
* Shopping cart indicator icons are scaled incorrectly #APPS-333
* Fixes deprecation warnings for iOS 13 and 14 
* CheckinManager available via Snabble
* Snabble changed to singled with a shared variable
* Clear Inflight checkouts as soon as checkoutProcess is completed #APPS-369

### Added
* Added dynamic fonts to several views #Apps-231
* Added dynamic fonts to PaydirektEditViewController #Apps-231
* Added dynamic fonts to PayoneCreditCardEditViewController #Apps-231
* Added dynamic fonts to SepaEditViewController #Apps-231
* Added dynamic fonts to TeleCashCreditCardEditViewController #Apps-231
* Added dynamic fints to PaymentMethodAddCell and PaymentMethodAddViewController #Apps-231
* Added dynamic fonts to SepaOverlayView #Apps-231
* Added dynamic fonts to Scanner section #Apps-231
* Added dynamic fonts to Checkout section #Apps-231
* Added dynamic fonts to ShoppingCartTableViewController and ShoppingCartTableCellView section #Apps-231
* Added dynamic fonts to ShoppingCartViewController #Apps-231
* Added dynamic fonts to CouponsListViewController #Apps-231
* Added plural forms #APPS-352

### Removed
* Xib/Nib utility methods

## [0.19.2] - 2022-5-25

### Changed
* Fixed black rating buttons
* Changed button types to `custom` if it's an image button

## [0.19.1] - 2022-05-24

### Added
* Added demo project credentials

### Changed
* Dispatch barcode detector offset calculation
* Fixed button appearance

### Updated
* Updated localizations 

## [0.19.0] - 2022-05-23

### Added
* Checkout Violations #110

### Changed
* Refactored ShoppingCartTableCellView to programmatically written UI #98
* Refactored PaydirektEditViewController to programmatically written UI #101
* Updated colors to semantic colors #100
* Refactor EmbeddedCodesCheckoutViewController #102
* Refactored ScannerDrawerViewController to programmatically written UI #104
* Refactored QRCheckoutViewController to programmatically written UI #105
* Refactored ScanningViewController to programmatically written UI #106
* Refactored CustomerCardCheckoutViewController to programmatically written UI #107
* Fixes BarcodeDetector yOffset calculation #APPS-316 

## Deprecated snabble iOS SDK Changelog

# v0.18.3
- Ability to restore a checkout which is in process

# v0.18.2
- Fixes a bug where the user could navigate away from the checkout status view while the checkout was still incomplete.

# v0.18.1
- Credit card entry via Telecash now enforces 3DS verification

# v0.18.0
- Major changes to the checkout flow. Handling the routing, checkout and finalization of the checkout (including fulfillments like e.g. product dispensing machines) is now completely handled by the SDK.
- QR codes for offline checkouts now include snabble's checkout ID, if present.


# v0.17.13
- This is the last version of the SDK with support for the React Native wrapper
- Adds a larger (4 module) quiet zone around QR codes in dark mode
- Fixes a bug where the payment selection was sometimes visible even if only one payment method was selectable

# v0.17.12
- Add support for credit card payment via PAYONE
- Fixes a bug where barcodes with embedded comma "," characters were not handled correctly
- New Feature: handling checking in and out at a store is now part of the SDK, in the `CheckInManager` class
- Fixes a bug where looking up products after extracting their code from a GS1 code would not alway succeed
- Fixes a bug where checkout via `qrCodeOffline` could fail while the device had not internet connectivity
- Fixes a bug where the scanner's energy saver timer was not stopped at the appropriate time
- For retailers that have Apple Pay enabled, wallets without matching credit cards are now correctly handled,
  and it is possible to add a card during the checkout process

# v0.17.11
- Fixes Payment Selection

# v0.17.10
- Adds support for the new `expectedBarcodeWidth` property
- Fixes various minor bugs related to payment method selection
- Made some visual improvements to the included Example app
- NOTE that after this version, support for the React Native wrapper of the SDK will be dropped 

# v0.17.9
- Fixes a payment method selection bug

# v0.17.8
- QR codes now include both `finalCode` and `manualCouponFinalCode`, if appropriate
- Restructured payment method entry and selection
- Fixes a bug where the scanner's energy saver hint could appear during the payment process
- Fixes a bug where some requests for assets could never be satisfied
- Fixes a bug where checkouts could be duplicated under very bad network connectivity conditions

# v0.17.7
- fixes a rare crash in `AssetManager`
- adds support for loading Coupons if the corresponding endpoint is present
- extends `Coupon` structure to add image, text and color data from a CMS
- adds `Accept-Language` header to all SDK network requests

# v0.17.6
- Add support for `requiredInformation` during checkout, e.g. for takeaway vs inhouse taxation

# v0.17.5
- Add support for credit card tokenization via Datatrans

# v0.17.4
- Add the new `loadActiveShops` config option to `SnabbleAPIConfig`

# v0.17.3
- Change sorting rules for shopping list entries
- Fixes a bug where aborting a cash desk payment could lead to problems

# v0.17.2
- Fixes some bugs related to payment method selection and Apple Pay
- Add support for "Tags" in the shopping list

# v0.17.1
- Updates the Datatrans SDK to v1.4
- Fixes a bug where completion handler for loading metadata could be called twice

# v0.17.0

- The SDK requires Xcode 12.5 or later to compile
- Fixes a bug in the asset manager where special assets for dark mode weren't found
- Creating the FTS index for a product database is now much faster
- Performance of `productsByName` and `productsByScannableCodePrefix` is now much better
- Product DB updates can now be triggered depending on when the last update was requested
- Completely redesigned the Scanner, with integrated shopping list and shopping cart in a Maps-like drawer. 
  To hide this drawer, pass `nil` for the `cartDelegate` init parameter.
- Add `CouponWallet` to store coupons, along with `CouponsListViewController` as the UI to manage coupons
- Add support for the new payment methods `twint` and `postFinanceCard`. To use these methods, add `pod 'Snabble/Datatrans'` to your app's `Podfile`, as these methods aren't included by default.
- Add support for Apple Pay

# v0.16.9

- the confirmation overlay for SEPA payments is now part of the SDK
- fixes a bug where errors in applying a diff update to the product db would not lead to a full db download

# v0.16.8

- Allow other filetypes besides .PNG as assets
- `SnabbleUI.appearance` is now public

# v0.16.7

- Made the notification for "new payment method added" public
- Made the Sets of fulfillment states public and added some convenience methods

# v0.16.6

- Adds support for displaying a text on the online payment screen
- When selecting a payment method with missing detail data, open the data entry view for this method

# v0.16.5

- Fixes a bug where barcode decoding would not restart after displaying a sale stop alert

# v0.16.4

- Adds support for entry tokens
- Fixes a bug where SCO payments couldn't be restarted after manual cancellation
- Fixes a bug where checkout processes weren't aborted even though the associcated checks indicated that this should happen

# v0.16.2

- Fixes the explanatory text when adding credit card data

# v0.16.0

- Changed the UI and the internal handling of payment methods to conform with PSD2 regulations

# v0.15.5

- Improves support for deposit return vouchers
- Checkout using embedded QR codes on very small devices now uses more screen space for the QR code itself

# v0.15.4

- `CustomAppearance` now relies on an `accentColor` and possibly a `secondaryAccentColor` for customization of UI elements.

# v0.15.3
- fixes out-of-range Crash (#16)
- add shop identifier to rating event (#15)

# v0.15.2

- Fixes a problem where the code for an exit gate would sometimes be missed.

# v0.15.1

- Removes the conformance to `Swift.Identifiable` from the SDK's `Identifiable`

# v0.15.0

- Adds localizable strings for `de` `sk`, and `hu` #5
- Adds `Identifier` for Brand, Project and Shop identifiers #9
- Remove `UIEmptyState` pod as dependency #6
- Updated the `Zip` dependency to v2.x
- Fixes a bug where double-tapping on a receipt could result in a crash

# v0.14.8

- Adds support for grouping multiple projects by their common `brand`.

# v0.14.7

- Removes the deprecated `discountedProducts()` method
- Fixes a bug where invalid price info could be extracted from a GS1 code
- Adds better support for UPC-A codes
- Checkout processes now have a locally generated ID
- Biometry/PIN protection is now enforced for all online payments
- Payment method selection now prefers SEPA (or other online payment methods), even if there is no detail data available yet

# v0.14.6

- Updates the CA hashes that are used for certificate pinning
- Scanning GS1 codes no longer requires use of Code128

# v0.14.5

- Fixes a bug where payment methods could be erroneously shown as valid for a purchase.

# v0.14.4

- Due to compatibility issues, the update of the `Zip` dependency to v2 was reverted. For the remainder of 2020, snabble will continue to use v1 of the library. The update to v2 will be re-introduced in January 2021.

# v0.14.3

- Adds support for the new `terms` object in an app's metadata.
- Adds support for the new `company` object in a project's metadata.
- Adds support for the new `exitToken` object in a checkout process.
- Adds support for the new product type `depositReturnVoucher`.
- When a project does not offer any offline payment methods, new payment method details can now be added during checkout.
- Fixes a bug where price override codes were sometimes not correctly parsed

# v0.14.2

- Fixes a bug where the notification to import IBAN data from the SCO could be sent twice
- Fix shopping cart initialization in the Sample app
- Add the `useCertificatePinning` property to the API config
- Adds support for decoding GS1 Codes to determine e.g. embedded weights
- Fixes a bug where codes with price overrides for products in bundles were handled incorrectly

# v0.14.1

- Scanning an age-restricted product now shows a corresponding message if the user's age is unknown.
- Add support for the new `isPrimary` and `specifiedQuantity` attributes that were added in db schema 1.24
- Minor layout changes to the online and embedded code checkout views.

# v0.14.0

- Breaking change: all methods for looking up products have been changed to deliver their result via a `Result<Product, ProductLookupError>` or `Result<ScannedProduct, ProductLookupError>` value.
- Deployment target of the SDK was changed to iOS 12 and later
- Fixes a bug where products marked as unvailable could still be scanned and added to the shopping cart
- Internal changes to the `BarcodeDetector` protocol so that it can be used from the new standalone scanner view in the RN wrapper

# v0.13.15

- Fixes a bug where receipts with empty PDF links were still displayed
- Reduces the timeout for creating the `CheckoutInfo` for offline payment methods to 3 seconds

# v0.13.14

- Add support for the new price category priorities
- The `ProductDB.discountedProducts` method is deprecated and will be removed in a future version of the SDK

# v0.13.12

- Add support for the new `notForSale` product property

# v0.13.11

- Fixes a bug where `displayNetPrice` did not actually show the net price

# v0.13.10

- Internal changes to `PaydirektEditViewController` so that it is usable from the RN wrapper

# v0.13.9

- Fixes a bug where VPoS price information with non-null `units` was displayed incorrectly
- Adds support for the `displayNetPrice` project setting
- Adds support for the `customerNetworks` store data property
- Fixes a rare crash in `ShoppingCartViewController.startCheckout()`

# v0.13.8

- Fixes a bug where polling for the payment status didn't continue after a failed attempt at payment cancellation.

# v0.13.7

- Adds a new UI for payment method selection, integrated into the shopping cart.
- The previously used `PaymentMethodSelectionViewController` has been removed, and `ShoppingCartDelegate.gotoPayment` has a new signature.
- Removes all methods/properties that were previously marked as `deprecated`.
- Fixes a potential crash bug when deleting a payment method
- The scanner confirmation dialog now only shows a strike price if the discounted price is different from the list price.

# v0.12.11

- Adds support for the `availabilities` table that was added in appdb schema v1.20. Searching for barcodes will now only return results that are marked as `listed` or `inStock`.
- Fixes display of the nav bar title in `ScannerViewController` and `ShoppingCartViewController` when switching between dark and light appearance.

# v0.12.10

- The status bar's appearance can now be controlled via `CustomAppearance`

# v0.12.9

- Adds support for the `fulfillments` property of the `CheckoutProcess`
- Minor breaking change: `PaymentDelegate.paymentFinished()` now has an additional parameter `rawJson`, containing the raw JSON representation of the `CheckoutProcess`.

# v0.12.8

- When changing the appUserId, any cached receipt PDFs are deleted

# v0.12.7

- Fixes a possible crash when online payments were successful before the `viewDidAppear()` was called

# v0.12.6

- Adds support for age verification checks during checkout

# v0.12.5

- Adds preliminary support for paydirekt.de
- Fixes a bug where too many files were downloaded from the snabble asset server after checkin

# v0.12.4

- Adds notifications for the appearance/disappearance of the scan confirmation dialog
- Suppress the "usable at" indication in single-project apps

# v0.12.3

- Fixes a bug where switching between the snabble server environments would lead do "unauthorized" errors

# v0.12.2

- Adds support for the new "CustomerCardPOS" payment method
- Adds support for the new "CreditCardAmericanExpress" payment method
- Links in the credit card entry form are now opened in Safari
- Adds support for adding IBAN data used at a snabble SCO as a payment method
- Fixes a bug where refreshing auth tokens could happen way too often
- Adds support for getting and setting the appUserId

# v0.12.1

- Exposes parts of the `Cart.Item` struct for the RN wrapper.

# v0.12.0

- Adds support for the upcoming React Native wrapper
- Adding and editing of payment method data (ie, SEPA and credit card data) is now part of the SDK. Use `PaymentMethodListViewController` as a starting point for letting users enter their payment data.
- Support for handling custom appearance (aka "chameleon mode") is now part of the SDK. See `SnabbleUI.registerForAppearanceChange()` and `SnabbleUI.setCustomAppearance()`
- Removes the unused `secondaryColor` property from `SnabbleAppearance`
- Fixes display of product weight in the Shopping Cart in Dark Mode
- Adds support for interactions with the [snabble vpos](https://github.com/snabble/docs/blob/master/api_vpos.md)
- Allows host apps to replace images used by the SDK's UI components. Whenever the SDK tries to load an image resource, it checks the app's main bundle for that image first, and only if no image is found takes the resource from the SDK's bundle. All images used by the SDK have been moved to the `SnabbleSDK` folder in `Snabble.xcassets` to avoid name collisions with assets in the hosting app.
- Fixes a bug where the wrong currency symbol could be used in price display
- "Restore Cart" is no longer available after a successful online payment.
- Checkout processing views for embedded codes and online payment methods have been redesigned and now show a visual indication of what the user is expected to do. The graphic resources for these views are not part of the SDK and must be provided by the host app as assets named `Checkout/<projectId>/checkout-offline` and/or `Checkout/<projectId>/checkout-online`, respectively.
- App Metadata is now saved on disk, and the last known good copy is used when loading fails on app start.
- Minor breaking change: the `CartConfig.shop` has been removed. Use the new `CartConfig.shopId` instead (ie., instead of passing in a shop object, just use its `id` property to create a cart config).
- Fixes a bug where adding items with price overrides from the scanned code could be incorrectly added to the shopping cart.

# v0.11.2

- Fixes a bug where the quantity of a shopping cart entry could be set to 0.

# v0.11.1

- Tapping a cell in `ReceiptListViewController` now correcly highlights it.
- Fixes a visual glitch in `ScannerViewController` when product names were extremely long (>100 characters)
- Adds support for the new `externalBilling` payment method.

# v0.11.0

- Swift 4.2 support has been removed
- Support for iOS 13 dark mode has been added. This means that Xcode 11.x is required to build apps using the snabble SDK.

# v0.10.21

- Fixes a crash when `ScanMessage.imageUrl` was nil.

# v0.10.20

- Extends the `ScanMessage` struct to add the new `attributedString` property. If it is not nil, it is used as the `attributedText` for the display and `text` is ignored.

# v0.10.19

- Improved handling of cancelling online payments. When the `CheckoutProcess.abort` backend API call returns an error, an alert is displayed using the new i18n keys `Snabble.Payment.cancelError.title` and `Snabble.Payment.cancelError.message`.
- Replaced `scanMessageText(for:)` in `ScannerDelegate` with `scanMessage(for:_:_:)` which returns a `ScanMessage?`. This allows apps to e.g. display product recommendations including images in the scanner's message area.

# v0.10.18

- Fixes a bug where the wrong date was used as an offline saved cart's `finalizedAt`
- Adds the new `AnalyticsEvent.brightnessChanged` to enable tracking of brightness changes in the QR code displays.
- The API's `clientId` is now stored in the keychain as well as in `Userdefaults.standard`.

# v0.10.17

- added the optional `sorter` property to `CartConfig`. When an offline QR code is generated that does not use the `nextItemWithCheck`, this callback is used to allow the hosting app to re-order the items in the shopping cart.
- fixes a bug where multiple appdb updates could still run simultaneously
- added a few new `AnalyticsEvent`s, deleted an old unused one, and renamed `.viewSepaCheckout` to `.viewOnlineCheckout`

# v0.10.16

- Adds the new `CustomAppearance` struct and the `CustomizableAppearance` protocol that can be used to change button apperances in the Scanner and Shopping Cart.
- `SnabbleAppearance.buttonBackgroundColor` is now consistently used for button backgrounds
- The bundle selection action sheet no longer shows bundles that don't have a price
- The SDK now allocates fewer `URLSession` instances for better HTTP/2 support
- Reduce the number of incomplete online payment methods that are shown in the payment method selection
- Support for Swift 4.2 is deprecated and will be removed on Oct 1st, 2019

# v0.10.15

- When creating a checkout info or checkout process fails and the payment reverts to an offline-capable QR code payment, the shopping cart is now persisted using the new `OfflineCarts` class. It is the hosting app's responsibiliy to attempt to retry posting this data to the backend at an appropriate time e.g. when it discovers that internet connectivity is restored. Use `OfflineCarts.shared.retryNeeded` to determine if there are carts pending retransmission.
- `BarcodeEntryViewController` has a new optional constructor parameter, `showSku`. If this is true, the SKUs of matching products are displays together with the product names.

# v0.10.14

- Decrease the memory usage when full appdb are downloaded.
- After a payment using an offline-capable QR code is completed, the previous shopping cart can now be restored.
- Adds support for ignoring variable-length code parts in templates using `{_:*}`
- The `finalCode` property of `qrCodeOffline` is now supported in all code variants

# v0.10.13

- The various offline-capable QR code payment methods (`encodedCodes`, `encodedCodesCSV` etc.) have been deprecated and were replaced by a new unified method called `qrCodeOffline`. This method is configured through the properties of the `qrCodeOffline` object in the app's metadata.

# v0.10.12

- Fixes a bug where a temporary database file could be kept on disk. Any such leftover files will be automatically cleaned up when the project database is initialized.

# v0.10.11

- Warning messages from the scanner are now displayed on the scanner view itself. Therefore, the `ScannerDelegate` protocol no longer requires conformance to `MessageDelegate`.
- Message localization now allows project-specific overrides.
- Fixes a bug where downloading the receipt list sometimes failed.

# v0.10.10

- Fixes a bug where the `encodedCodes` payment method was used as a fallback even in stores that don't support it.
- Adds support for accessing arbitrary additional data in the `Metadata.flags` object
- Changes the title of the Receipt view controller to show the receipt's date.

# v0.10.9

- Adds a temporary implementation for project-specific strings in `EmbeddedCodesCheckoutViewController`

# v0.10.8

- Adds support for restricting QR codes to maximum string lengths instead of max. number of codes.

# v0.10.7

- Fixes a bug where some codes using an "embedded decimal" template would not be interpreted correctly.

# v0.10.6

- Fixes a bug in `BuiltinBarcodeDetector` where the scanner overlay would not appear in simulator builds.

# v0.10.5

- Protect against simultaneous appdb updates. When an appdb update is requested while a previous request is already waiting for completion, the completion handler is immediately called with `.inProgess`.

# v0.10.4

- Add missing parameter to the default implementation of `PaymentDelegate.handlePaymentError()`

# v0.10.3

- adds the `Project.paymentMethods` property
- `PaymentDelegate.handlePaymentError()` method now takes two parameters, the `PaymentMethod` as well as the `Error` that occurred

# v0.10.2

- Adds support for new payment methods, `creditCardVisa` and `creditCardMastercard`.
- Adds pull-to-refresh to `ReceiptsListViewController`.
- `ReceiptsListViewController.init` now takes an optional `CheckoutProcess` parameter. If this is used, the VC will add the specified order to the table display, if it's not already in the client's order list, and wait for the receipt PDF to be generated.
- The `PaymentDelegate.paymentFinished()` method has a new third parameter of type `CheckoutProcess?` to allow passing the current process from the payment views to the receipt list.

# v0.10.1

- Fixes a bug where store-specific prices would sometimes be reported as 0.

# v0.10.0

This version implements a number of major changes in different areas.

- The scanning subsystem as been redesigned. It is now much easier to plug in other barcode detector systems instead of the built-in metadata detector from iOS. To enable this, the following breaking changes were made:
- The previously available `ScanningView` has been replaced by the `BarcodeDetector` protocol and the `BuiltinBarcodeDetector` implementation (based on the iOS built-in `AVCaptureMetadataOutput`)
- For custom implementations of `BarcodeDetector`, the overlay that is placed on top of the camera preview is available via `BarcodeDetectorDecoration`. The configuration of that decoration is made through a `BarcodeDetectorAppearance` instance, which replaces the old `ScanningViewConfig` struct.
- `ScannerViewController` has a new optional parameter `detector` of type `BarcodeDetector?`. Pass your own implementation of the protocol, or leave it as nil to use the default built-in implementation.
- Sample code for implementations of `BarcodeDetector` based on third-party SDKs (currently [Digimarc](https://www.digimarc.com/solutions/mobilesdk), [MLKit Vision](https://developers.google.com/ml-kit/vision/barcode-scanning/), [Scandit](https://www.scandit.com/developers/) and [Tachyoniq](https://www.tachyoniq.com/software-solutions/cortexdecoder-2/)) is available upon request.
- The `reset` method in `ScannerViewController` has been removed. When switching between projects or shops, create new instances of the Scanner instead.

- Also in the scanner, custom messages can be displayed e.g. when scanning products that consist of multiple packages to remind customers. The new product property `scanMessage` is passed to the `scanMessageText` method of `ScannerDelegate` where it should be used to lookup or create a user-visible message. When the delegate method returns a non-nil String, that is displayed in a simple UIAlertController.

- Support for special prices when a customer card is present. `ShoppingCart` has a new property `customerCard` (replacing the previous `loyaltyCard` in `ShoppingCartConfig`) which is used in the Scanner and Shopping Cart views to fetch/display prices from the `customerCardPrice` of products, if available. The previous `price` and `priceWithDeposit` Product properties have been deprecated in favor of the new methods of the same name that both take a customer card (or `nil`) as their parameter.

- Tapping the "Cancel" button on one of the views that wait for payment approval/processing no longer pops the navigation stack back to the root, but only to the `ShoppingCartViewController` instance.

- The previously deprecated public `none` instances of `Project` and `Shop` have been removed.
- The previously deprecated `additionalCodes` property of `ShoppingCart` has been removed.

# v0.9.26

- The public `Project.none` and `Shop.none` instances have been decreated and will be removed soon.
- The `name` property has been added to `Project`, it contains the display name of each project that is already visible in the retailer portal.

# v0.9.25

- Update `GRDB.swift` to v4.x and specify compatibility with Swift versions 4.2 and 5.0 in `Snabble.podspec`. From this version onward, cocoapods v1.7.0 or later is required to install the SDK. The deprecated `.swiftversion` file has been removed.

# v0.9.24

- Adds client-side support for resuming failed downloads of the product database (this feature is not yet enabled on our backend servers). Apps can use the new `appDbAvailability` property of `ProductProvider` to determine if the last download attempt was incomplete, and can call `resumeAbortedUpdate` when connectivity is restored (monitoring connectivity is the app's responsibility, e.g. via one of the various `Reachability` implementations). This new feature makes a minor breaking change to the parameter of the closure invoked by the `setup` and `updateDatabase` methods of `ProductProvider`: the type has changed from `Bool` to `AppDbAvailability`.

# v0.9.23

- Removes the back button from `SepaCheckoutViewController`

# v0.9.22

- Marks the `CartConfig.loyaltyCard` property as deprecated. Please implement ` ShoppingCartDelegate.getLoyaltyCard(_:)` instead

# v0.9.21

- Fixes a bug where the wrong receipt could be displayed when selecting multiple receipts in `ReceiptsViewController`

# v0.9.19

- Adds support for the `code=constant` format in code templates.
- Disables the idle timer while waiting for an online payment.

# v0.9.18

- Fixes a bug in bug in `PaymentProcessPoller` where the polling would not detect rejected payments correctly

# v0.9.17

- Fixes some minor layout issues in `PaymentMethodSelectionViewController`.
- Fixes a bug in `PaymentProcessPoller` where the polling would not stop when the customer's (debit) card was rejected in the initial check.
- Avoids a potential race condition where the "checkout limit" alerts could be presented while the naviation hierarchy changed.
- Fixes a problem in `ShoppingCartViewController` where the view was not always correctly refreshed after emptying the cart.
- Avoids multiple `createCheckoutInfo` being in-flight

# v0.9.16

- Fixes a bug where the torch button on `ScanningView` could remain highlighted when the torch was actually off.
- Fixes a visual glitch when deleting the last item in the shopping cart
- Marks the `additionalCodes` property of the shopping cart as deprecated. This property will be removed in a future release.

# v0.9.15

- Fixes a bug where the taptic feedback would be triggered twice on the first scan after starting the app
- Fixes a bug where the camera preview would not start immediately after granting camera permission

# v0.9.14

- Adds a new error message when no payment methods are available during checkout. This uses the new localization key `Snabble.Payment.noMethodAvailable`.

# v0.9.13

- Loyalty cards set in the shopping cart are now also included in the QR code that is shown when one of the `encodedCode` payment mehtods is used.

# v0.9.12

- Layout changes in the scanner confirmation view and the shopping cart table cells.
- full appdb downloads are now always used
- fixes barcode entry for codes that did not match the `default` template
- fixes a bug where the camera preview was not stopped after the very first scan after starting the app

# v0.9.11

- Fixes a bug in the shopping cart's display of products with deposits
- Renames the payment method `teleCashDeDirectDebit` to just `deDirectDebit`
- Fixes bug where invalid barcodes could be transmitted to the backend

# v0.9.10

- Fixes a bug when scanning a regular (non-instore) EAN of a product that has `encodingUnit == piece`.

# v0.9.9

- When scanning a product that has `saleStop`, a warning alert is shown. This uses the new localization key `Snabble.saleStop.errorMsg.scan`. The product is not added to the shopping cart.
- Adds support for the new `checkoutLimits` project metadata. Alerts are displayed when these limits are reached, using the new localization keys `Snabble.limitsAlert.title`, `Snabble.limitsAlert.notAllMethodsAvailable` and `Snabble.limitsAlert.checkoutNotAvailable`.
- Breaking change: The layout of the scanning view has changed, and the `ScanningViewConfig` struct has changed to reflect this. New configuration properties have been added: `torchButtonActiveImage`, `backgroundColor` and `borderColor`. The properties `title`, `enterButtonTitle` and `torchButtonTitle` have been removed. The new "go to cart" button uses the localization keys `Snabble.Scanner.goToCart` and `Snabble.Scanner.goToCart.empty`
- `ScanningViewDelegate` has a new method `gotoShoppingCart` that is called when the shopping cart should be displayed.
- Fixes a bug where invalid barcodes could be transmitted to the backend after scanning items with `piece` encoding.

# v0.9.8

- fixes a bug in the price display for products without price data, e.g. for consigments
- fixes a bug in the price data transmission for barcodes that override a product's reference price

# v0.9.7

- The shopping cart now shows the price information as delivered from the backend as part of the `CheckoutInfo` data, if available. This data is updated automatically, and `ShoppingCartViewController` also now has a pull-to-refresh function.
- Text shown on the payment method selection screen has changed slightly and now uses the `Snabble.PaymentSelection.payNow` localization key.

# v0.9.6

- `ShoppingCartViewContoller` now handles notifications that arrive before `viewDidLoad` is called.

# v0.9.5

- fixes a bug in the price display of products with deposits

# v0.9.4

- `ShoppingCartViewController` and both QR-Code-based checkout views now display price information from the backend, if available.

# v0.9.3

- `QRCheckoutViewController` now displays the same "price may differ" message that is already present on `EmbeddedCodesCheckoutViewController` (localization key `Snabble.QRCode.priceMayDiffer`)

# v0.9.2

- `ScanningView` now supports using a custom barcode detector, e.g. one based on Firebase/MLKit. Such a detector needs to conform to the `BarcodeDetector` protocol, and be passed to the scanning view as part of its configuration, namely in the `barcodeDetector` property. In order to de-couple the detector from `AVFoundation`, the various `objectTypes` properties have been renamed to `scanFormats` and are now arrays of `ScanFormat`, an enum that represents the barcode formats supported by the SDK, with the same case names as are used in `AVMetadataObject.ObjectType`.

# v0.9.1

- refactored a lot of common code from `ScanConfirmationView` and `ShoppingCartTableCell` into the `ShoppingCart` and `CartItem` structs. This is mostly invisible for users of the UI components, but has a bunch of breaking changes for the Core API. In particular, the static methods of `PriceFormatter` are gone.

# v0.9.0

- removed the deprecated `discountedProducts` and `boostedProducts` methods
- Products now have an optional property `encodingUnit` that specified how it is measured in scannable codes. The most common example is groceries with a `referenceUnit` of kg and and `encodingUnit` of g. This encoding can be overridden by specific scannable codes.
- decoding of embedded data in scanned codes no longer relies on project-specific prefixes. Instead, codes are now parsed using templates that extract the embedded data (if any) and map to the `encodingUnit` used. This is a major breaking change for users of the Core API, but transparent if only the UI components are used.
- all methods referring to `weighItemIds` have been removed, since product lookup now only occurs through the scanned codes resulting from the template parsing.
- this new information can be accessed using a product's `codes` property, an array of `ScannableCode` objects. This replaces the previous `scannableCodes` property.

# v0.8.13

- fixes a bug with unit-encoded EANs

# v0.8.12

- add support for the CSV-based QR Code payment method
- add support for the `referenceUnit` product property

# v0.8.11

- made `BarcodeEntryViewController` public

# v0.8.10

- fixes some small and rare memory leaks
- adds the optional `customerCard` property to `Project`

# v0.8.9

- fixes two rare crash bugs
- renamed `ApiError` to `SnabbleError` and changed its optionality in the `handleXYZError` delegate methods
- the `PaymentProcess.start` method now calls its closure argument with a `Result` instance which is modeled after the recently approved SE-0235 proposal.
- likewise, the asynchronous methods `productBySku`, `productByScannableCode` and `productByWeighItemId` have been changed so that ttheir completion closure now also takes a `Result` argument.

# v0.8.8

- Change button style

# v0.8.7

- add CA pinning to all https connections the SDK makes. Call `SnabbleAPI.urlSession()` to get a `URLSession` that implements this behaviour.

# v0.8.6

- add `ShoppingCart.updateProducts()`

# v0.8.5

- show "shelf code scanned" message when the scanned EAN has no or 0 as its embedded data.

# v0.8.4

- fixes a bug in the price query for the default price category

# v0.8.3

- improve performance of product database queries that return price information

# v0.8.2

- all classes that don't need to be (implicitly) `open` are now `final`

# v0.8.1

- fixes a bug in `ProductDB.discountedProducts()`

# v0.8.0

- fixes a bug with shop-specific prices
- added `SnabbleApiConfig.maxProductDatabaseAge`. Product lookups in the local database are only made if the last update of the db is not longer ago than this value. Default value is 1 hour.
- added `AnalyticsEvent.viewSepaCheckout`
- added support for handling Telecash direct debit payments in Germany.
- The HTTP `User-Agent` header for SDK requests now contains detailed information about the hardware and OS version of the user's device.

# v0.7.9

- added a very simple example app
- removed the redundant `project` parameter from `ScannerViewController.init` and `ScannerViewController.reset` - the class now fully relies on `SnabbleUI.project`

# v0.7.8

- add additional log info when product db updates fail with i/o errors

# v0.7.7

- fixes a bug where the scanner confirmation dialog was incorrectly positioned when the keyboard appeared/disappeared

# v0.7.6

- `ScannerViewController.reset()` now has a third parameter, `shop`

# v0.7.5

- add support for special ITF14 and DataMatrix barcodes
- `ScanningViewDelegate.scannedCode` changed to take a second parameter, the detected code type. New signature is `func scannedCode(_ code: String, _ type: AVMetadataObject.ObjectType)`

# v0.7.4

- fix a bug where the scanner's capture session was started on every layout pass
- tactile scanning confirmation now uses `UINotificationFeedbackGenerator`

# v0.7.3

- add support for shop-specific price information, introduced in database schema v1.15. This brings another set of breaking changes:
- most Core API methods that retrieve product information now require an additional parameter, namely the identifier of the shop that the price information should relate to.
- `ProductProvider.boostedProducts` has been deprecated and will be removed in a future version of the SDK.
- Likewise, `ProductProvider.discountedProducts` has been deprecated and will be removed soon. Use `ProductProvider.discountedProducts(_:)` instead.
- `productsByName` and `productsByScannableCodePrefix` still return products, but without price information (price fields are 0 or nil, respectively)
- `CartConfig.shopId` has been replaced with the new property `shop` (of type `Shop`).
- Receipts for successful checkouts are now downloaded automatically as soon as they're ready. Use `ReceiptManager` to manage the receipts, and `ReceiptListViewController` to display them in a QuickLook preview.

# v0.7.2

- add `reticleHeight` property to `ScanningViewConfig`
- `ScanningView` now renders `reticleCornerRadius` correctly

# v0.7.1

- removes global static state that was previously kept by the core SDK. This results in breaking changes to the initialization and usage:
- to initialize the SDK, create a `SnabbleAPIConfig` object and pass it to `SnabbleAPI.setup`. For single-project apps, the project to use is available as `SnabbleAPI.projects[0]`.
- `ProductDBConfiguration` has been removed, the relevant configuration info is now part of `SnabbleAPIConfig`. Call `SnabbleAPI.productProvider(for:)` to get the `ProductProvider` instance for a project.
- the current project to be used by the UI components has to be set using `SnabbleUI.registerProject()`
- `UIConfig` has been renamed to `SnabbleAppearance`. To configure the UI appearance, create an instance and pass it to `SnabbleUI.setup()`.
- Price calculation and formatting methods have moved from the `Price` and `Product` structs to static methods in `PriceFormatter`.

# v0.7.0

- add support for multi-project apps. All of the following changes break existing clients.
- requires Swift 4.2/Xcode 10
- removes the need to use hard-coded JWTs per app, authorization tokens are instead created on-demand using HOTP
- `Shop.distance` property was removed
- class `AppData` has been replaced by `Metadata` which implements the new app-scoped API endpoint
- accordingly, app initialization now has to use the new app-scoped API endpoint URLs that looks like `/metadata/app/{appID}/{platform}/{version}`
- `ScannerViewController.init` now needs to be passed a `Shop` instance
- `APIConfig.setup` and `SnabbleProject` have been removed. Instead, use `TokenRegistry.shared.setup()` and `APIConfig.registerProject()` during app setup to initialize the SDK. Contact snabble to get the required app secret and id.
- When the user first scans an item and adds it to their shopping cart, a special confirmation alert is shown, using the new localization keys `Snabble.Hints.*`

# v0.6.6

- product bundles are now delivered as the `bundles` property of each product retrieved, and if they are not found locally, they are dynamically loaded from the server.
- breaking change: `ProductDBConfiguration` no longer has individual url properties, but uses the existing `MetadataLinks` struct instead.

# v0.6.5

- Add support for scanning shelf codes with an encoded # of units of 0.

# v0.6.3

- adds the `forceFullDownload` parameter to the `setup` and `updateDatabase` methods of `ProductProvider`.

# v0.6.2

- add UI support for bundled products

# v0.6.0

- Breaking Change: `productsByName` will only continue to work if the `ProductDBConfiguration.useFTS` flag is set. Our appdb servers will stop providing the underlying FTS tables soon.
- Removed the deprecation warnings from `productsByName`.

# v0.5.8

- add the `additionalCodes` property to `ShoppingCart`, mainly for use in the embedded QR code payment
- avoid showing the camera permission request when `ScannerViewController.reset` is called before the scanner was ever on screen

# v0.5.7

- Add support for scanning UPC-A, either directly or embedded in an EAN-13.
- Breaking change: the return type of the `productByScannableCode` method has changed, it now returns a `LookupResult` struct that contains both the product and the code by which it was found.

# v0.5.6

- Breaking change: `APIConfig.shared.setup` is gone, use `APIConfig.setup` instead
- Add support for scanning EAN-14 code
- manual Barcode entry adds the displayed barcode to the shopping cart

# v0.5.5

- add error callbacks to PaymentDelegate and ShoppingCartDelegate (breaking change)
- error responses from the backend are now available in all completion callbacks
- add support for (re)creating the FTS index locally. This is not used yet, but will become a requirement for using the `productsByName` method in the near future

# v0.5.3

- Add support for german magazine/newspaper EANs

# v0.5.0

- Miscellaneous fixes regarding products with weight-dependent price.
- Breaking change: many of the properties of `SnabbleProject` were removed, they are now automatically set using the information from the app metadata `project` object.

# v0.4.3

- Fix `productsBySku` for non-integer SKUs

# v0.4.2

- New feature: first-time display of the scanner displays an info layer (tapping on the (i) icon later also shows this layer)
- Breaking change: direct usage of ScanningView needs one additional step during the initializiation: make sure to call `intializeCamera()` after calling `setup()`

# v0.4.1

- Fix a crash on devices without a torch.

# v0.4.0

- mark the productsByName methods as deprecated
- finish the conversion of SKUs to Strings. This requires product databases with at least schema version 1.8
