## snabble iOS SDK Changelog

# v0.9.14

* Adds a new error message when no payment methods are available during checkout. This uses the new localization key `Snabble.Payment.noMethodAvailable`.

# v0.9.13

* Loyalty cards set in the shopping cart are now also included in the QR code that is shown when one of the `encodedCode` payment mehtods is used.

# v0.9.12

* Layout changes in the scanner confirmation view and the shopping cart table cells.
* full appdb downloads are now always used
* fixes barcode entry for codes that did not match the `default` template
* fixes a bug where the camera preview was not stopped after the very first scan after starting the app

# v0.9.11

* Fixes a bug in the shopping cart's display of products with deposits
* Renames the payment method `teleCashDeDirectDebit` to just `deDirectDebit`
* Fixes bug where invalid barcodes could be transmitted to the backend

# v0.9.10

* Fixes a bug when scanning a regular (non-instore) EAN of a product that has `encodingUnit == piece`.

# v0.9.9

* When scanning a product that has `saleStop`, a warning alert is shown. This uses the new localization key `Snabble.saleStop.errorMsg.scan`. The product is not added to the shopping cart.
* Adds support for the new `checkoutLimits` project metadata. Alerts are displayed when these limits are reached, using the new localization keys `Snabble.limitsAlert.title`, `Snabble.limitsAlert.notAllMethodsAvailable` and `Snabble.limitsAlert.checkoutNotAvailable`.
* Breaking change: The layout of the scanning view has changed, and the `ScanningViewConfig` struct has changed to reflect this. New configuration properties have been added: `torchButtonActiveImage`, `backgroundColor` and `borderColor`. The properties `title`, `enterButtonTitle` and `torchButtonTitle` have been removed. The new "go to cart" button uses the localization keys `Snabble.Scanner.goToCart` and `Snabble.Scanner.goToCart.empty`
* `ScanningViewDelegate` has a new method `gotoShoppingCart` that is called when the shopping cart should be displayed.
* Fixes a bug where invalid barcodes could be transmitted to the backend after scanning items with `piece` encoding.

# v0.9.8

* fixes a bug in the price display for products without price data, e.g. for consigments
* fixes a bug in the price data transmission for barcodes that override a product's reference price

# v0.9.7

* The shopping cart now shows the price information as delivered from the backend as part of the `CheckoutInfo` data, if available. This data is updated automatically, and `ShoppingCartViewController` also now has a pull-to-refresh function.
* Text shown on the payment method selection screen has changed slightly and now uses the `Snabble.PaymentSelection.payNow` localization key.

# v0.9.6

* `ShoppingCartViewContoller` now handles notifications that arrive before `viewDidLoad` is called.

# v0.9.5

* fixes a bug in the price display of products with deposits

# v0.9.4

* `ShoppingCartViewController` and both QR-Code-based checkout views now display price information from the backend, if available.

# v0.9.3

* `QRCheckoutViewController` now displays the same "price may differ" message that is already present on `EmbeddedCodesCheckoutViewController` (localization key `Snabble.QRCode.priceMayDiffer`)

# v0.9.2

* `ScanningView` now supports using a custom barcode detector, e.g. one based on Firebase/MLKit. Such a detector needs to conform to the `BarcodeDetector` protocol, and be passed to the scanning view as part of its configuration, namely in the `barcodeDetector` property. In order to de-couple the detector from `AVFoundation`, the various `objectTypes` properties have been renamed to `scanFormats` and are now arrays of `ScanFormat`, an enum that represents the barcode formats supported by the SDK, with the same case names as are used in `AVMetadataObject.ObjectType`.

# v0.9.1

* refactored a lot of common code from `ScanConfirmationView` and `ShoppingCartTableCell` into the `ShoppingCart` and `CartItem` structs. This is mostly invisible for users of the UI components, but has a bunch of breaking changes for the Core API. In particular, the static methods of `PriceFormatter` are gone.

# v0.9.0

* removed the deprecated `discountedProducts` and `boostedProducts` methods
* Products now have an optional property `encodingUnit` that specified how it is measured in scannable codes. The most common example is groceries with a `referenceUnit` of kg and and `encodingUnit` of g. This encoding can be overridden by specific scannable codes.
* decoding of embedded data in scanned codes no longer relies on project-specific prefixes. Instead, codes are now parsed using templates that extract the embedded data (if any) and map to the `encodingUnit` used. This is a major breaking change for users of the Core API, but transparent if only the UI components are used.
* all methods referring to `weighItemIds` have been removed, since product lookup now only occurs through the scanned codes resulting from the template parsing.
* this new information can be accessed using a product's `codes` property, an array of `ScannableCode` objects. This replaces the previous `scannableCodes` property.

# v0.8.13

* fixes a bug with unit-encoded EANs

# v0.8.12

* add support for the CSV-based QR Code payment method
* add support for the `referenceUnit` product property

# v0.8.11

* made `BarcodeEntryViewController` public

# v0.8.10

* fixes some small and rare memory leaks
* adds the optional `customerCard` property to `Project`

# v0.8.9

* fixes two rare crash bugs
* renamed `ApiError` to `SnabbleError` and changed its optionality in the `handleXYZError` delegate methods
* the `PaymentProcess.start` method now calls its closure argument with a `Result` instance which is modeled after the recently approved SE-0235 proposal.
* likewise, the asynchronous methods `productBySku`, `productByScannableCode` and `productByWeighItemId` have been changed so that ttheir completion closure now also takes a `Result` argument.

# v0.8.8

* Change button style

# v0.8.7

* add CA pinning to all https connections the SDK makes. Call  `SnabbleAPI.urlSession()` to get a `URLSession` that implements this behaviour.

# v0.8.6

* add `ShoppingCart.updateProducts()`

# v0.8.5

* show "shelf code scanned" message when the scanned EAN has no or 0 as its embedded data.

# v0.8.4

* fixes a bug in the price query for the default price category

# v0.8.3

* improve performance of product database queries that return price information

# v0.8.2

* all classes that don't need to be (implicitly) `open` are now `final`

# v0.8.1

* fixes a bug in `ProductDB.discountedProducts()`

# v0.8.0

* fixes a bug with shop-specific prices
* added `SnabbleApiConfig.maxProductDatabaseAge`. Product lookups in the local database are only made if the last update of the db is not longer ago than this value. Default value is 1 hour.
* added `AnalyticsEvent.viewSepaCheckout`
* added support for handling Telecash direct debit payments in Germany.
* The HTTP `User-Agent` header for SDK requests now contains detailed information about the hardware and OS version of the user's device.

# v0.7.9

* added a very simple example app
* removed the redundant `project` parameter from `ScannerViewController.init` and `ScannerViewController.reset` - the class now fully relies on `SnabbleUI.project`

# v0.7.8

* add additional log info when product db updates fail with i/o errors

# v0.7.7

* fixes a bug where the scanner confirmation dialog was incorrectly positioned when the keyboard appeared/disappeared

# v0.7.6

* `ScannerViewController.reset()` now has a third parameter, `shop`

# v0.7.5

* add support for special ITF14 and DataMatrix barcodes
* `ScanningViewDelegate.scannedCode` changed to take a second parameter, the detected code type. New signature is `func scannedCode(_ code: String, _ type: AVMetadataObject.ObjectType)`

# v0.7.4

* fix a bug where the scanner's capture session was started on every layout pass
* tactile scanning confirmation now uses `UINotificationFeedbackGenerator`

# v0.7.3

* add support for shop-specific price information, introduced in database schema v1.15. This brings another set of breaking changes:
* most Core API methods that retrieve product information now require an additional parameter, namely the identifier of the shop that the price information should relate to.
* `ProductProvider.boostedProducts` has been deprecated and will be removed in a future version of the SDK.
* Likewise, `ProductProvider.discountedProducts` has been deprecated and will be removed soon. Use `ProductProvider.discountedProducts(_:)` instead.
* `productsByName` and `productsByScannableCodePrefix` still return products, but without price information (price fields are 0 or nil, respectively)
* `CartConfig.shopId` has been replaced with the new property `shop` (of type `Shop`).
* Receipts for successful checkouts are now downloaded automatically as soon as they're ready. Use `ReceiptManager` to manage the receipts, and `ReceiptListViewController` to display them in a QuickLook preview.

# v0.7.2

* add `reticleHeight` property to `ScanningViewConfig`
* `ScanningView` now renders `reticleCornerRadius` correctly

# v0.7.1

* removes global static state that was previously kept by the core SDK. This results in breaking changes to the initialization and usage:
* to initialize the SDK, create a `SnabbleAPIConfig` object and pass it to `SnabbleAPI.setup`. For single-project apps, the project to use is available as `SnabbleAPI.projects[0]`.
* `ProductDBConfiguration` has been removed, the relevant configuration info is now part of `SnabbleAPIConfig`. Call `SnabbleAPI.productProvider(for:)` to get the `ProductProvider` instance for a project.
* the current project to be used by the UI components has to be set using `SnabbleUI.registerProject()`
* `UIConfig` has been renamed to `SnabbleAppearance`. To configure the UI appearance, create an instance and pass it to `SnabbleUI.setup()`.
* Price calculation and formatting methods have moved from the `Price` and `Product` structs to static methods in `PriceFormatter`. 

# v0.7.0

* add support for multi-project apps. All of the following changes break existing clients.
* requires Swift 4.2/Xcode 10
* removes the need to use hard-coded JWTs per app, authorization tokens are instead created on-demand using HOTP
* `Shop.distance` property was removed
* class `AppData` has been replaced by `Metadata` which implements the new app-scoped API endpoint
* accordingly, app initialization now has to use the new app-scoped API endpoint URLs that looks like `/metadata/app/{appID}/{platform}/{version}`
* `ScannerViewController.init` now needs to be passed a `Shop` instance
* `APIConfig.setup` and `SnabbleProject` have been removed. Instead, use `TokenRegistry.shared.setup()` and `APIConfig.registerProject()` during app setup to initialize the SDK. Contact snabble to get the required app secret and id.
* When the user first scans an item and adds it to their shopping cart, a special confirmation alert is shown, using the new localization keys `Snabble.Hints.*`

# v0.6.6

* product bundles are now delivered as the `bundles` property of each product retrieved, and if they are not found locally, they are dynamically loaded from the server.
* breaking change: `ProductDBConfiguration` no longer has individual url properties, but uses the existing `MetadataLinks` struct instead.

# v0.6.5

* Add support for scanning shelf codes with an encoded # of units of 0.

# v0.6.3

* adds the `forceFullDownload` parameter to the `setup` and `updateDatabase` methods of `ProductProvider`.

# v0.6.2

* add UI support for bundled products

# v0.6.0

* Breaking Change: `productsByName` will only continue to work if the `ProductDBConfiguration.useFTS` flag is set. Our appdb servers will stop providing the underlying FTS tables soon.
* Removed the deprecation warnings from `productsByName`.

# v0.5.8

* add the `additionalCodes` property to `ShoppingCart`, mainly for use in the embedded QR code payment
* avoid showing the camera permission request when `ScannerViewController.reset` is called before the scanner was ever on screen

# v0.5.7

* Add support for scanning UPC-A, either directly or embedded in an EAN-13.
* Breaking change: the return type of the `productByScannableCode` method has changed, it now returns a `LookupResult` struct that contains both the product and the code by which it was found.

# v0.5.6

* Breaking change: `APIConfig.shared.setup` is gone, use `APIConfig.setup` instead
* Add support for scanning EAN-14 code
* manual Barcode entry adds the displayed barcode to the shopping cart

# v0.5.5

* add error callbacks to PaymentDelegate and ShoppingCartDelegate (breaking change)
* error responses from the backend are now available in all completion callbacks
* add support for (re)creating the FTS index locally. This is not used yet, but will become a requirement for using the `productsByName` method in the near future

# v0.5.3

* Add support for german magazine/newspaper EANs

# v0.5.0

* Miscellaneous fixes regarding products with weight-dependent price.
* Breaking change: many of the properties of `SnabbleProject` were removed, they are now automatically set using the information from the app metadata `project` object.

# v0.4.3

* Fix `productsBySku` for non-integer SKUs

# v0.4.2 

* New feature: first-time display of the scanner displays an info layer (tapping on the (i) icon later also shows this layer)
* Breaking change: direct usage of ScanningView needs one additional step during the initializiation: make sure to call `intializeCamera()` after calling `setup()`

# v0.4.1

* Fix a crash on devices without a torch.

# v0.4.0

* mark the productsByName methods as deprecated
* finish the conversion of SKUs to Strings. This requires product databases with at least schema version 1.8
