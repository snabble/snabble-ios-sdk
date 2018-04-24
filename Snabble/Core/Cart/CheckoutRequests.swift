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
    ///   - timeout: the timeout for the HTTP request (0 for no timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///    with either a `SignedCheckoutInfo` object or `nil` if an error occurred
    public func createCheckoutInfo(timeout: TimeInterval = 0, completion: @escaping (SignedCheckoutInfo?) -> () ) {
        let items = self.items.map { Cart.Item(sku: $0.product.sku, amount: $0.quantity) }
        let customerInfo = Cart.CustomerInfo(loyaltyCard: self.config.loyaltyCard)
        let cart = Cart(session: UUID().uuidString, shopID: self.config.shopId, customer: customerInfo, items: items)

        guard let request = SnabbleAPI.request(.post, self.config.checkoutInfoUrl, body: cart, timeout: timeout) else {
            completion(nil)
            return
        }

        SnabbleAPI.perform(request, returnRaw: true) { (result: SignedCheckoutInfo?, json) in
            var newResult = result
            newResult?.rawJson = json
            completion(newResult)
        }
    }

}

extension SignedCheckoutInfo {

    // since we need to pass the originally-received SignedCheckoutInfo as-is,
    // we can't use the struct but have to build this manually:
    struct CreateCheckoutProcess {
        let paymentMethod: String
        let signedCheckoutInfo: SignedCheckoutInfo
    }

    /// create a checkout process
    ///
    /// - Parameters:
    ///   - paymentMethod: the user's chosen payment method
    ///   - timeout: the timeout for the HTTP request (0 for no timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///     with either a `CheckoutProcess` object or `nil` if an error occurred
    public func createCheckoutProcess(paymentMethod: PaymentMethod, timeout: TimeInterval = 0, completion: @escaping (CheckoutProcess?) -> () ) {
        do {
            var dict = [String: Any]()
            dict["paymentMethod"] = paymentMethod.rawValue
            dict["signedCheckoutInfo"] = self.rawJson

            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            guard let request = SnabbleAPI.request(.post, self.links.checkoutProcess.href, body: data, timeout: timeout) else {
                completion(nil)
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
    ///    - timeout: the timeout for the HTTP request (0 for no timeout)
    ///    - completion: is called on the main thread with the result of the API call,
    ///      with either a `CheckoutProcess` object or `nil` if an error occurred
    @discardableResult
    public func update(timeout: TimeInterval = 0, completion: @escaping (CheckoutProcess?) -> () ) -> URLSessionDataTask? {
        guard let url = APIConfig.shared.urlFor(self.links.`self`.href) else {
            completion(nil)
            return nil
        }

        let request = SnabbleAPI.request(.get, url, timeout: timeout)
        return SnabbleAPI.perform(request, completion)
    }

    /// abort this checkout process
    ///
    /// - Parameters:
    ///    - timeout: the timeout for the HTTP request (0 for no timeout)
    ///    - completion: is called on the main thread with the result of the API call,
    ///      with either a `CheckoutProcess` object or `nil` if an error occurred
    public func abort(timeout: TimeInterval = 0, completion: @escaping (CheckoutProcess?) -> () ) {
        let abort = AbortRequest(aborted: true)
        guard let request = SnabbleAPI.request(.patch, self.links.`self`.href, body: abort, timeout: timeout) else {
            completion(nil)
            return
        }

        SnabbleAPI.perform(request, completion)
    }

}

