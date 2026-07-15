//
//  PaymentDelegate.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit
import SnabbleCore
import SnabbleComponents

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

    /// Called when a payment flow needs to navigate to a new view controller.
    /// UIKit hosts can implement this via UINavigationController directly.
    /// SwiftUI hosts (e.g. Shopper) implement this to update their driven controller state.
    /// Must be a protocol requirement (not only an extension default) so dynamic dispatch
    /// routes to the concrete conformer's implementation, not the static default.
    func paymentRequiresNavigation(to viewController: UIViewController)
}

/// provide simple default implementations
extension PaymentDelegate {
    public func handlePaymentError(_ method: PaymentMethod, _ error: SnabbleError) -> Bool {
        return false
    }

    public func paymentRequiresNavigation(to viewController: UIViewController) {}
}
