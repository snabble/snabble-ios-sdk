//
//  PaymentDelegate.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation
import UIKit

/// a protocol that users of `PaymentProcess` must implement
public protocol PaymentDelegate: AnalyticsDelegate, MessageDelegate {
    /// called before a given payment method is run.
    /// Call the `completion` closure with an argument of `true` to continue the process, `false` to abort it.
    func startPayment(_ method: PaymentMethod, _ presenter: UIViewController, _ completion: @escaping (Bool)->() )

    /// callback when the payment is finished
    ///
    /// - Parameters:
    ///   - success: indicates whether the payment was successful
    ///   - cart: the shopping cart
    func paymentFinished(_ success: Bool, _ cart: ShoppingCart)

    /// a view that the payment process can use to temporarily display e.g. loading indicators
    /// (this uses `UIView!` as the type so that instances of `UIViewController` don't need to do anything to conform)
    var view: UIView! { get }

    /// callback when an error occurred
    ///
    /// - Parameter error: the error from the backend
    /// - Returns: true if the error has been dealt with and no error messages need to be shown from the SDK
    func handlePaymentError(_ error: SnabbleError) -> Bool

    /// get payment data from the host app. Use this method to return e.g. encrypted SEPA data for use with .deDirectDebit to the SDK
    func getPaymentData() -> [PaymentMethod]

    /// for payment methods with missing data (e.g. Telecash, but no SEPA data available), provide a `UIViewController` instance that allows the user
    /// to enter the missing data
    func dataEntry(for: PaymentMethod) -> UIViewController?
}

/// provide simple default implementations
extension PaymentDelegate {

    public func startPayment(_ method: PaymentMethod, _ presenter: UIViewController, _ completion: @escaping (Bool)->() ) {
        completion(true)
    }

    public func handlePaymentError(_ error: SnabbleError) -> Bool {
        return false
    }

    public func getPaymentData() -> [PaymentMethod] {
        return []
    }

    public func dataEntry(for: PaymentMethod) -> UIViewController? {
        return nil
    }

}
