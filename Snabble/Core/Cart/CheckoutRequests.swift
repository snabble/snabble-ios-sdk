//
//  CheckoutRequests.swift
//
//  Copyright © 2020 snabble. All rights reserved.
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
    public func createCheckoutInfo(_ project: Project, timeout: TimeInterval = 0, completion: @escaping (_ result: Result<SignedCheckoutInfo, SnabbleError>) -> Void ) {
        // cancel any previous tasks
        self.eventTimer?.invalidate()
        self.checkoutInfoTask?.cancel()

        let cart = self.createCart()

        Log.info("create checkout session: \(cart.session)")

        let url = project.links.checkoutInfo.href
        project.request(.post, url, body: cart, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            let task = project.perform(request, returnRaw: true) { (_ result: Result<SignedCheckoutInfo, SnabbleError>, json, _) in
                self.checkoutInfoTask = nil
                switch result {
                case .success(var value):
                    value.rawJson = json
                    completion(Result.success(value))
                case .failure:
                    completion(result)
                }
            }
            self.checkoutInfoTask = task
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
    public func createCheckoutProcess(_ project: Project, paymentMethod: PaymentMethod, timeout: TimeInterval = 0, finalizedAt: Date? = nil,
                                      completion: @escaping (_ result: Result<CheckoutProcess, SnabbleError>) -> Void ) {
        do {
            // since we need to pass the originally-received SignedCheckoutInfo as-is,
            // we can't use the struct but have to build this manually:
            var dict = [String: Any]()
            dict["paymentMethod"] = paymentMethod.rawMethod.rawValue
            dict["signedCheckoutInfo"] = self.rawJson

            if let data = paymentMethod.data {
                var paymentInformation = [
                    "originType": data.originType.rawValue,
                    "encryptedOrigin": data.encryptedData
                ]
                if let cardNumber = paymentMethod.cardNumber {
                    paymentInformation["cardNumber"] = cardNumber
                }
                if let validUntil = paymentMethod.validUntil {
                    paymentInformation["validUntil"] = validUntil
                }

                dict["paymentInformation"] = paymentInformation
            }

            if let finalizedAt = finalizedAt {
                dict["processedOffline"] = true
                dict["finalizedAt"] = Snabble.iso8601Formatter.string(from: finalizedAt)
            }

            if let checkoutInfo = self.rawJson?["checkoutInfo"] as? [String: Any], let session = checkoutInfo["session"] as? String {
                Log.info("checkout process for session: \(session)")
            }

            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            project.request(.post, self.links.checkoutProcess.href, body: data, timeout: timeout) { request in
                guard let request = request else {
                    return completion(Result.failure(SnabbleError.noRequest))
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
                       taskCreated: @escaping (_ task: URLSessionDataTask) -> Void,
                       completion: @escaping (_ result: Result<CheckoutProcess, SnabbleError>) -> Void ) {

        project.request(.get, self.links.`self`.href, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
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
    public func abort(_ project: Project, timeout: TimeInterval = 0, completion: @escaping (_ result: Result<CheckoutProcess, SnabbleError>) -> Void ) {
        let abort = AbortRequest(aborted: true)

        project.request(.patch, self.links.`self`.href, body: abort, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            project.perform(request, completion)
        }
    }

}
