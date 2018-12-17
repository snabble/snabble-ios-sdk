//
//  CheckoutRequests.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

extension ShoppingCart {

    /// create a SignedCheckoutInfo object
    ///
    /// create a new "checkout session" and sends the current cart to the backend.
    /// - Parameters:
    ///   - project: the project for this request
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - completion: is called on the main thread with the result of the API call
    ///   - result: the `SignedCheckoutInfo` or the error
    public func createCheckoutInfo(_ project: Project, timeout: TimeInterval = 0, completion: @escaping (_ result: Result<SignedCheckoutInfo, ApiError>) -> () ) {
        let items = self.items.map { $0.cartItem() }
        let customerInfo = Cart.CustomerInfo(loyaltyCard: self.loyaltyCard)
        let cart = Cart(session: self.session, shopID: self.shopId, customer: customerInfo, items: items)

        Log.info("create checkout session: \(cart.session)")
        let url = project.links.checkoutInfo.href
        project.request(.post, url, body: cart, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(ApiError.noRequest))
            }

            project.perform(request, returnRaw: true) { (_ result: Result<SignedCheckoutInfo, ApiError>, json, _) in
                switch result {
                case .success(var value):
                    value.rawJson = json
                    completion(Result.success(value))
                case .failure:
                    completion(result)
                }
            }
        }
    }

}

extension SignedCheckoutInfo {

    /// create a checkout process
    ///
    /// - Parameters:
    ///   - project: the project for this request
    ///   - paymentMethod: the user's chosen payment method
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///   - result: the newly created `CheckoutProcess` or the error
    public func createCheckoutProcess(_ project: Project, paymentMethod: PaymentMethod, timeout: TimeInterval = 0, completion: @escaping (_ result: Result<CheckoutProcess, ApiError>) -> () ) {
        do {
            // since we need to pass the originally-received SignedCheckoutInfo as-is,
            // we can't use the struct but have to build this manually:
            var dict = [String: Any]()
            dict["paymentMethod"] = paymentMethod.rawMethod.rawValue
            dict["signedCheckoutInfo"] = self.rawJson

            if let data = paymentMethod.data {
                dict["paymentInformation"] = [ "encryptedOrigin": data.encryptedData ]
            }

            if let checkoutInfo = self.rawJson?["checkoutInfo"] as? [String: Any], let session = checkoutInfo["session"] as? String {
                Log.info("check process for session: \(session)")
            }

            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            project.request(.post, self.links.checkoutProcess.href, body: data, timeout: timeout) { request in
                guard let request = request else {
                    return completion(Result.failure(ApiError.noRequest))
                }

                project.perform(request, completion)
            }
        } catch {
            Log.error("error serializing request body: \(error)")
        }
    }

}

extension CheckoutProcess {

    /// get the current state of this checkout process
    ///
    /// - Parameters:
    ///   - the project for this request
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - taskCreated: is called with the `URLSessionTask` created for the request
    ///   - task: the `URLSessionTask`
    ///   - completion: is called on the main thread with the result of the API call
    ///   - result: the `CheckoutProcess` returned from the backend or the error
    public func update(_ project: Project,
                       timeout: TimeInterval = 0,
                       taskCreated: @escaping (_ task: URLSessionDataTask) -> (),
                       completion: @escaping (_ result: Result<CheckoutProcess, ApiError>) -> () ) {

        project.request(.get, self.links.`self`.href, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(ApiError.noRequest))
            }

            let task = project.perform(request, completion)
            taskCreated(task)
        }
    }

    /// abort this checkout process
    ///
    /// - Parameters:
    ///   - project: the project for this request
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - completion: is called on the main thread with the result of the API call,
    ///   - result: the `CheckoutProcess` returned from the backend or the error
    public func abort(_ project: Project, timeout: TimeInterval = 0, completion: @escaping (_ result: Result<CheckoutProcess, ApiError>) -> () ) {
        let abort = AbortRequest(aborted: true)

        project.request(.patch, self.links.`self`.href, body: abort, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(ApiError.noRequest))
            }

            project.perform(request, completion)
        }
    }

}

