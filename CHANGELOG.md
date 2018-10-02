## snabble iOS SDK changelog

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








