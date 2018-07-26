//
//  PaymentDelegate.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

/// a protocol that users of `PaymentProcess` must implement
public protocol PaymentDelegate: AnalyticsDelegate, MessageDelegate {
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
    /// - Parameter error: if not nil, the ApiError from the backend
    /// - Returns: true if the error has been dealt with and no error messages need to be shown from the SDK
    func handlePaymentError(_ error: ApiError?) -> Bool
}
