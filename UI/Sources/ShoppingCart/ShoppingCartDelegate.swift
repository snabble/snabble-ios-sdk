//
//  ShoppingCartDelegate.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import SnabbleCore

/// a protocol that users of `ShoppingCartViewController` must implement
@MainActor
public protocol ShoppingCartDelegate: AnalyticsDelegate, MessageDelegate {
    /// called to determine if starting the checkout process is allowed/possible,
    /// e.g. after asking the user's confirmation
    /// it is this method's responsibility to display corresponding error messages
    /// calls the `completion` to indicate whether the checkout process should start
    func checkoutAllowed(project: Project, cart: ShoppingCart, completion: @escaping @Sendable (Bool) -> Void)

    /// called when the user wants to initiate payment.
    /// Implementations should usually create a `PaymentProcess` instance and invoke its `start` method
    func gotoPayment(_ method: RawPaymentMethod,
                     _ detail: PaymentMethodDetail?,
                     _ info: SignedCheckoutInfo,
                     _ cart: ShoppingCart,
                     _ didStartPayment: @escaping (Bool) -> Void)

    /// called from the standalone shopping cart to switch to the scanner view
    func gotoScanner()

    /// called when an error occurred
    ///
    /// - Parameter error: the error from the backend
    /// - Returns: true if the error has been dealt with and no error messages need to be shown from the SDK
    func handleCheckoutError(_ error: SnabbleError) -> Bool
}

extension ShoppingCartDelegate {
    public func checkoutAllowed(project: Project, cart: ShoppingCart, completion: @escaping @Sendable (Bool) -> Void) {
        completion(true)
    }

    public func handleCheckoutError(_ error: SnabbleError) -> Bool {
        return false
    }
}
