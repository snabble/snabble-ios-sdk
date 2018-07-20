//
//  CheckoutRequests.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

extension ShoppingCart {

    /// create a SignedCheckoutInfo object
    ///
    /// create a new "session" and sends the current cart to the backend.
    /// - Parameters:
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///    with either a `SignedCheckoutInfo` object or `nil` if an error occurred
    public func createCheckoutInfo(timeout: TimeInterval = 0, completion: @escaping (SignedCheckoutInfo?, ApiError?) -> () ) {
        let items = self.items.map { $0.cartItem() }
        let customerInfo = Cart.CustomerInfo(loyaltyCard: self.loyaltyCard)
        let cart = Cart(session: self.session, shopID: self.shopId, customer: customerInfo, items: items)

        NSLog("create checkout session: \(cart.session)")
        guard let request = SnabbleAPI.request(.post, self.checkoutInfoUrl, body: cart, timeout: timeout) else {
            completion(nil, nil)
            return
        }

        SnabbleAPI.perform(request, returnRaw: true) { (result: SignedCheckoutInfo?, error, json) in
            var newResult = result
            newResult?.rawJson = json
            completion(newResult, error)
        }
    }

}

extension SignedCheckoutInfo {

    /// create a checkout process
    ///
    /// - Parameters:
    ///   - paymentMethod: the user's chosen payment method
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///   - process: the newly created `CheckoutProcess`, or nil on error
    ///   - error: if not nil, contains the error response from the backend
    public func createCheckoutProcess(paymentMethod: PaymentMethod, timeout: TimeInterval = 0, completion: @escaping (_ process: CheckoutProcess?, _ error: ApiError?) -> () ) {
        do {
            // since we need to pass the originally-received SignedCheckoutInfo as-is,
            // we can't use the struct but have to build this manually:
            var dict = [String: Any]()
            dict["paymentMethod"] = paymentMethod.rawValue
            dict["signedCheckoutInfo"] = self.rawJson

            if let checkoutInfo = self.rawJson?["checkoutInfo"] as? [String: Any], let session = checkoutInfo["session"] as? String {
                NSLog("check process for session: \(session)")
            }

            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            guard let request = SnabbleAPI.request(.post, self.links.checkoutProcess.href, body: data, timeout: timeout) else {
                completion(nil, nil)
                return
            }

            SnabbleAPI.perform(request, completion)
        } catch {
            NSLog("error serializing request body: \(error)")
        }
    }

}

extension CheckoutProcess {

    /// get the current state of this checkout process
    ///
    /// - Parameters:
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///   - process: the `CheckoutProcess` returned from the backend, or nil on error
    ///   - error: if not nil, contains the error response from the backend
    /// - Returns:
    ///    a `URLSessionDataTask` object or nil (if the request couldn't be started)
    @discardableResult
    public func update(timeout: TimeInterval = 0, completion: @escaping (_ process: CheckoutProcess?, _ error: ApiError?) -> () ) -> URLSessionDataTask? {
        guard let url = APIConfig.shared.urlFor(self.links.`self`.href) else {
            completion(nil, nil)
            return nil
        }

        let request = SnabbleAPI.request(.get, url, timeout: timeout)
        return SnabbleAPI.perform(request, completion)
    }

    /// abort this checkout process
    ///
    /// - Parameters:
    ///   - timeout: the timeout for the HTTP request (0 for no timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///   - process: the `CheckoutProcess` returned from the backend, or nil on error
    ///   - error: if not nil, contains the error response from the backend
    public func abort(timeout: TimeInterval = 0, completion: @escaping (_ process: CheckoutProcess?, _ error: ApiError?) -> () ) {
        let abort = AbortRequest(aborted: true)
        guard let request = SnabbleAPI.request(.patch, self.links.`self`.href, body: abort, timeout: timeout) else {
            completion(nil, nil)
            return
        }

        SnabbleAPI.perform(request, completion)
    }

}

