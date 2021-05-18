//
//  ShoppingCartDelegate.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

/// a protocol that users of `ShoppingCartViewController` must implement
public protocol ShoppingCartDelegate: AnalyticsDelegate, MessageDelegate {
    /// called to determine if checking out is possible, e.g. if required customer card data is present
    /// it is this method's responsibility to display corresponding error messages
    func checkoutAllowed(_ project: Project) -> Bool

    /// called when the user wants to initiate payment.
    /// Implementations should usually create a `PaymentProcess` instance and invoke its `start` method
    func gotoPayment(_ method: RawPaymentMethod, _ detail: PaymentMethodDetail?, _ info: SignedCheckoutInfo, _ cart: ShoppingCart)

    /// called when an error occurred
    ///
    /// - Parameter error: the error from the backend
    /// - Returns: true if the error has been dealt with and no error messages need to be shown from the SDK
    func handleCheckoutError(_ error: SnabbleError) -> Bool
}

extension ShoppingCartDelegate {
    func checkoutAllowed(_ project: Project) -> Bool {
        return true
    }

    func handleCheckoutError(_ error: SnabbleError) -> Bool {
        return false
    }
}
