//
//  Analytics.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

public protocol AnalyticsDelegate: class {
    func track(_ event: AnalyticsEvent)
}

public enum AnalyticsEvent {

    /// views events are tracked in `viewDidAppear` of the corresponding view controllers
    /// the `ScanningViewController` appeared
    case viewScanner

    /// the `BarcodeEntryViewController` appeared
    case viewBarcodeEntry

    /// the `ShoppingCartViewController` appeared
    case viewShoppingCart

    /// the `PaymentMethodSelectionViewController` appeared
    case viewPaymentMethodSelection

    /// the `CashCheckoutViewController` appeared
    case viewCashCheckout

    /// the `QRCodeCheckoutViewController` appeared
    case viewQRCodeCheckout

    /// the `EmbeddedCodesCheckoutViewController` appeared
    case viewEmbeddedCodesCheckout

    /// other events are tracked as a response to user actions

    /// toggling the scanner's torch
    case toggleTorch

    /// successful scan of `code`, corresponding product was found. associated value is the scanned EAN code
    case scanProduct(String)

    /// successful scan of `code`, no corresponding product was found. associated value is the scanned EAN code
    case scanUnknown(String)

    /// product was scanned, but scan confirmation was closed w/o adding it to the cart. associated value is the product's `sku`
    case scanAborted(String)
    
    /// a barcode was selected from the autocomplete list. associated value is the selected EAN code
    case barcodeSelected(String)

    /// product was deleted from the cart. associated value is the product's `sku`
    case deletedFromCart(String)

    /// the entire cart was cleared
    case deletedEntireCart

    /// the user tappped "cancel" on the payment screen
    case paymentCancelled

    /// the user tapped "I have paid" on the embedded codes payment screen
    case markEmbeddedCodesPaid
}
