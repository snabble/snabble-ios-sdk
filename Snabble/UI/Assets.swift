// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "SwiftGenImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = SwiftGenImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum SnabbleSDK {
    internal static let arrowUp = SwiftGenImageAsset(name: "SnabbleSDK/arrow-up")
    internal static let barcodeOverlay = SwiftGenImageAsset(name: "SnabbleSDK/barcode-overlay")
    internal static let iconBarcode = SwiftGenImageAsset(name: "SnabbleSDK/icon-barcode")
    internal static let iconCartActive = SwiftGenImageAsset(name: "SnabbleSDK/icon-cart-active")
    internal static let iconCartInactiveEmpty = SwiftGenImageAsset(name: "SnabbleSDK/icon-cart-inactive-empty")
    internal static let iconCartInactiveFull = SwiftGenImageAsset(name: "SnabbleSDK/icon-cart-inactive-full")
    internal static let iconCheckLarge = SwiftGenImageAsset(name: "SnabbleSDK/icon-check-large")
    internal static let iconChevronDown = SwiftGenImageAsset(name: "SnabbleSDK/icon-chevron-down")
    internal static let iconClose = SwiftGenImageAsset(name: "SnabbleSDK/icon-close")
    internal static let iconEntercode = SwiftGenImageAsset(name: "SnabbleSDK/icon-entercode")
    internal static let iconGiveaway = SwiftGenImageAsset(name: "SnabbleSDK/icon-giveaway")
    internal static let iconLightActive = SwiftGenImageAsset(name: "SnabbleSDK/icon-light-active")
    internal static let iconLightInactive = SwiftGenImageAsset(name: "SnabbleSDK/icon-light-inactive")
    internal static let iconMinus = SwiftGenImageAsset(name: "SnabbleSDK/icon-minus")
    internal static let iconPercent = SwiftGenImageAsset(name: "SnabbleSDK/icon-percent")
    internal static let iconPlus = SwiftGenImageAsset(name: "SnabbleSDK/icon-plus")
    internal static let iconScanActive = SwiftGenImageAsset(name: "SnabbleSDK/icon-scan-active")
    internal static let iconScanInactive = SwiftGenImageAsset(name: "SnabbleSDK/icon-scan-inactive")
    internal static let iconTrash = SwiftGenImageAsset(name: "SnabbleSDK/icon-trash")
    internal enum Payment {
      internal static let paymentAmex = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-amex")
      internal static let paymentApplePay = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-apple-pay")
      internal static let paymentGirocard = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-girocard")
      internal static let paymentGooglePay = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-google-pay")
      internal static let paymentMastercard = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-mastercard")
      internal static let paymentPaydirekt = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-paydirekt")
      internal static let paymentPaypal = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-paypal")
      internal static let paymentPos = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-pos")
      internal static let paymentPostfinance = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-postfinance")
      internal static let paymentSco = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-sco")
      internal static let paymentSepa = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-sepa")
      internal static let paymentTegut = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-tegut")
      internal static let paymentTwint = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-twint")
      internal static let paymentVisa = SwiftGenImageAsset(name: "SnabbleSDK/payment/payment-visa")
    }
    internal static let paymentMethodCheckstand = SwiftGenImageAsset(name: "SnabbleSDK/payment-method-checkstand")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct SwiftGenImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

internal extension SwiftGenImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the SwiftGenImageAsset.image property")
  convenience init?(asset: SwiftGenImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
