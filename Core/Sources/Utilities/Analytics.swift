//
//  Analytics.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

@MainActor
public protocol AnalyticsDelegate: AnyObject {
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

    /// the `OnlineCheckoutViewController` appeared
    case viewOnlineCheckout

    /// the `TerminalCheckoutViewController` appeared
    case viewTerminalCheckout

    /// the `ApplePayCheckoutViewController` appeared
    case viewApplePayCheckout

    /// the `QRCodeCheckoutViewController` appeared
    case viewQRCodeCheckout

    /// the `EmbeddedCodesCheckoutViewController` appeared
    case viewEmbeddedCodesCheckout

    /// the `CustomerCardCheckoutViewController` appeared
    case viewCustomerCardCheckout

    /// the `CheckoutStepsViewController` appeared
    case viewCheckoutSteps

    /// the `ReceiptListViewController` appeared
    case viewReceiptList

    /// the quicklook preview for a single receipt appeared
    case viewReceiptDetail

    /// the `PaymentMethodListViewController` appeared
    case viewPaymentMethodList

    /// the `PaymentMethodDetailViewController` appeared
    case viewPaymentMethodDetail

    /// other events are tracked as a response to user actions

    /// toggling the scanner's torch
    case toggleTorch

    /// successful scan of `code`, corresponding product was found. associated value is the scanned EAN code
    case scanProduct(String)

    /// successful scan of `code`, no corresponding product was found. associated value is the scanned EAN code
    case scanUnknown(String)

    /// product was scanned, but scan confirmation was closed w/o adding it to the cart. associated value is the product's `sku`
    case scanAborted(String)

    /// a product was added to the shopping cart. associated value is the product's `sku`
    case productAddedToCart(String)

    /// a barcode was selected from the autocomplete list. associated value is the selected EAN code
    case barcodeSelected(String)

    /// a product's amount was changed via the +/- buttons in the shopping cart
    case cartAmountChanged

    /// product was deleted from the cart. associated value is the product's `sku`
    case deletedFromCart(String)

    /// the entire cart was cleared
    case deletedEntireCart

    /// the user tappped "cancel" on the payment screen
    case paymentCancelled

    /// the checkout was rejected by a supervisor or gatekeeper
    case checkoutRejected

    /// the user tapped "I have paid" on the embedded codes payment screen
    case markEmbeddedCodesPaid

    /// the screen brightness needed to be increased in the checkout screen
    case brightnessIncreased

    /// the named payment method was added
    case paymentMethodAdded(String)

    /// the named payment method was deleted
    case paymentMethodDeleted(String)

    /// an item was manually marked "done" in the shopping list drawer
    case itemMarkedDone

    /// an item was manually marked "todo" in the shopping list drawer
    case itemMarkedTodo

    /// an item was marked "done" in the shopping list drawer by scanning the corresponding product
    case itemMarkedDoneScanner

    /// an tag was marked "done" in the shopping list drawer by scanning a corresponding product
    case tagMarkDoneScanner

    /// checkout rating has been submitted
    case ratingSubmitted(value: Int)

    /// closed checkoutSteps
    case checkoutStepsClosed
}
