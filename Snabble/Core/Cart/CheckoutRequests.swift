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
        self.eventTimer?.invalidate()
        // cancel any previous tasks
        self.cancelPendingCheckoutInfoRequest()

        let cart = self.createCart()

        Log.info("create checkout session: \(cart.session)")

        let url = project.links.checkoutInfo.href
        project.request(.post, url, body: cart, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            let task = project.performRaw(request) { (_ result: RawResult<SignedCheckoutInfo, SnabbleError>) in
                self.checkoutInfoTask = nil
                switch result.result {
                case .success(var value):
                    value.rawJson = result.rawJson
                    completion(Result.success(value))
                case .failure(let error):
                    Log.error("\(error)")
                    completion(result.result)
                }
            }

            self.checkoutInfoTask = task
        }
    }

    func cancelPendingCheckoutInfoRequest() {
        self.checkoutInfoTask?.cancel()
        self.checkoutInfoTask = nil
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
                                      completion: @escaping (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) {
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

                for (key, value) in paymentMethod.additionalData {
                    paymentInformation[key] = value
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
                    return completion(RawResult.failure(SnabbleError.noRequest))
                }

                project.performRaw(request, completion)
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
    ///   - project: the project for this request
    ///   - timeout: the timeout for the HTTP request (0 for the system default timeout)
    ///   - taskCreated: is called with the `URLSessionTask` created for the request
    ///   - task: the `URLSessionTask`
    ///   - completion: is called on the main thread with the result of the API call
    ///   - result: the `CheckoutProcess` returned from the backend or the error
    public func update(_ project: Project,
                       timeout: TimeInterval = 0,
                       taskCreated: @escaping (_ task: URLSessionDataTask) -> Void,
                       completion: @escaping (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) {

        project.request(.get, self.links.`self`.href, timeout: timeout) { request in
            guard let request = request else {
                let rawResult = RawResult<CheckoutProcess, SnabbleError>.failure(SnabbleError.noRequest)
                return completion(rawResult)
            }

            let task = project.performRaw(request) { (_ result: RawResult<CheckoutProcess, SnabbleError>) in
                completion(result)
            }

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
