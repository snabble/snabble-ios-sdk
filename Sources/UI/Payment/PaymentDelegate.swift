//
//  PaymentDelegate.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit
import SnabbleCore

/// a protocol that users of `PaymentProcess` must implement
public protocol PaymentDelegate: AnalyticsDelegate, MessageDelegate {
    // callback when the checkout is finished
    ///
    /// - Parameters:
    ///   - cart: the shopping cart
    ///   - process: the checkout process, if available
    func checkoutFinished(_ cart: ShoppingCart, _ process: CheckoutProcess?)

    /// a view that the payment process can use to temporarily display e.g. loading indicators
    /// (this uses `UIView!` as the type so that instances of `UIViewController` don't need to do anything to conform)
    var view: UIView! { get }

    /// callback when an error occurred
    ///
    /// - Parameter error: the error from the backend
    /// - Returns: true if the error has been dealt with and no error messages need to be shown from the SDK
    func handlePaymentError(_ method: PaymentMethod, _ error: SnabbleError) -> Bool

    func exitToken(_ exitToken: ExitToken, for shop: Shop)
}

/// provide simple default implementations
extension PaymentDelegate {
    public func handlePaymentError(_ method: PaymentMethod, _ error: SnabbleError) -> Bool {
        return false
    }
}
