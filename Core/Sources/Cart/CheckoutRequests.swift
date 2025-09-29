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
    public func createCheckoutInfo(_ project: Project, timeout: TimeInterval = 0, completion: @escaping @Sendable (_ result: Result<SignedCheckoutInfo, SnabbleError>) -> Void ) {
        self.eventTimer?.invalidate()
        // cancel any previous tasks
        self.cancelPendingCheckoutInfoRequest()

        let cart = self.createCart()

//         uncomment to show the raw JSON of the cart we're posting
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
//        let data = try? encoder.encode(cart)
//        let str = String(bytes: data!, encoding: .utf8)!
//        print(str)

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
                    completion(.success(value))
                case .failure(let error):
                    Log.error("\(error)")
                    completion(result.result)
                }
            }

            self.checkoutInfoTask = task
        }
    }

    public func cancelPendingCheckoutInfoRequest() {
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
    public func createCheckoutProcess(_ project: Project,
                                      id: String,
                                      paymentMethod: PaymentMethod,
                                      timeout: TimeInterval = 0,
                                      finalizedAt: Date? = nil,
                                      completion: @escaping @Sendable (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) {
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
                if paymentMethod.rawMethod == .externalBilling,
                   data.originType == .contactPersonCredentials,
                   let subject = globalButterOverflow {
                    paymentInformation["subject"] = subject
                }
                dict["paymentInformation"] = paymentInformation
            }

            if let finalizedAt = finalizedAt {
                dict["processedOffline"] = true
                dict["finalizedAt"] = Formatter.iso8601.string(from: finalizedAt)
            }

            if let checkoutInfo = self.rawJson?["checkoutInfo"] as? [String: Any], let session = checkoutInfo["session"] as? String {
                Log.info("checkout process for session: \(session)")
            }

            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let url = self.links.checkoutProcess.href + "/" + id
            project.request(.put, url, body: data, timeout: timeout) { request in
                guard let request = request else {
                    return completion(RawResult.failure(SnabbleError.noRequest))
                }

                project.performRaw(request) { (result: RawResult<CheckoutProcess, SnabbleError>) in
                    switch result.result {
                    case .success:
                        completion(result)
                    case .failure(let error):
                        if let statusCode = error.statusCode, statusCode == 409 || statusCode == 403 {
                            // this means that somehow we already have a process with this id in the backend.
                            // GET that process, and return it to the caller
                            Log.warn("got 409/403 from PUT to checkoutProcess, try GET")
                            CheckoutProcess.fetch(for: project, url: url, completion)
                        } else if case .urlError = error, !paymentMethod.rawMethod.offline {
                            // ignore urlErrors if this is an offline method
                            CheckoutProcess.fetch(for: project, url: url, completion)
                        } else {
                            completion(result)
                        }
                    }
                }
            }
        } catch {
            Log.error("error serializing request body: \(error)")
        }
    }
}

extension CheckoutProcess {
    public static func fetch(for project: Project, url: String, _ completion: @escaping @Sendable (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) {
        project.request(.get, url, timeout: 3) { request in
            guard let request = request else {
                return completion(RawResult.failure(SnabbleError.noRequest))
            }

            project.performRaw(request) { (result: RawResult<CheckoutProcess, SnabbleError>) in
                switch result.result {
                case .success:
                    completion(result)
                case .failure(let error):
                    if case .urlError = error {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            Self.fetch(for: project, url: url, completion)
                        }
                    } else {
                        completion(result)
                    }
                }
            }
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
                       taskCreated: @escaping @Sendable (_ task: URLSessionDataTask) -> Void,
                       completion: @escaping @Sendable (_ result: RawResult<CheckoutProcess, SnabbleError>) -> Void ) {

        project.request(.get, self.links._self.href, timeout: timeout) { request in
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
    public func abort(_ project: Project, timeout: TimeInterval = 0, completion: @escaping @Sendable (_ result: Result<CheckoutProcess, SnabbleError>) -> Void ) {
        let abort = AbortRequest(aborted: true)

        project.request(.patch, self.links._self.href, body: abort, timeout: timeout) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            project.perform(request, completion)
        }
    }
}
