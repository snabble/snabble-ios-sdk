//
//  ApplePayCheckoutViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import PassKit

public final class ApplePayCheckoutViewController: BaseCheckoutViewController {
    private var authController: UIViewController?
    private let countryCode: String?
    private var currentProcess: CheckoutProcess?
    private var authorized = false

    override public init(_ process: CheckoutProcess, _ rawJson: [String: Any]?, _ cart: ShoppingCart, _ delegate: PaymentDelegate?) {
        // Apple Pay needs the two-letter ISO country code for the payment. Try to extract that from the various contryCode fields we have
        // in `Shop` and `Project.Company`, which may or may not have 3- or 2-letter codes. Oh well...
        self.countryCode = Self.getCountryCode(from: cart)

        super.init(process, rawJson, cart, delegate)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - base class overrides

    override func showQrCode(_ process: CheckoutProcess) -> Bool {
        return checksPending(in: process)
    }

    override func qrCodeContent(_ process: CheckoutProcess, _ id: String) -> String {
        return process.paymentInformation?.qrCodeContent ?? id
    }

    override var viewEvent: AnalyticsEvent { .viewApplePayCheckout }

    // called from the base class whenever the checkout process is initialized or updated
    override func processUpdated(_ process: CheckoutProcess) {
        self.currentProcess = process

        if self.authController == nil, !checksPending(in: process), let applePayAuth = createApplePayProcessor(for: process) {
            if process.supervisorApproval == true {
                self.authController = applePayAuth
                self.present(applePayAuth, animated: true)
            }
        }
    }

    private func checksPending(in process: CheckoutProcess) -> Bool {
        let checksNeedingSupervisor = process.checks.filter { $0.performedBy == .supervisor && $0.state != .successful }
        return process.supervisorApproval == nil || !checksNeedingSupervisor.isEmpty
    }

    // MARK: - apple pay

    private func createApplePayProcessor(for process: CheckoutProcess) -> UIViewController? {
        guard
            let merchantId = process.paymentPreauthInformation?.merchantID,
            let countryCode = self.countryCode
        else {
            return nil
        }

        let project = SnabbleUI.project
        let decimalDigits = project.decimalDigits

        let paymentRequest = PKPaymentRequest()
        paymentRequest.applicationData = process.id.data(using: .utf8)
        paymentRequest.merchantIdentifier = merchantId
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = process.currency
        paymentRequest.supportedNetworks = ApplePay.paymentNetworks(with: project.id)
        paymentRequest.merchantCapabilities = .capability3DS

        let totalAmount = decimalPrice(process.pricing.price.price, decimalDigits)
        let sumItem = PKPaymentSummaryItem(label: project.name, amount: totalAmount)
        paymentRequest.paymentSummaryItems = [sumItem]

        let applePayAuth = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
        applePayAuth?.delegate = self

        return applePayAuth
    }

    private func decimalPrice(_ price: Int?, _ decimalDigits: Int) -> NSDecimalNumber {
        let divider = pow(Decimal(10), decimalDigits)
        let decimalPrice = Decimal(price ?? 0) / divider
        return decimalPrice as NSDecimalNumber
    }

    // POST the payment authorization token we get from the PassKit API to our backend
    private func performPayment(with process: CheckoutProcess?,
                                and token: PKPaymentToken,
                                completion: @escaping (_ success: Bool) -> Void) {
        guard let authorizeUrl = process?.links.authorizePayment?.href else {
            return completion(false)
        }

        let project = SnabbleUI.project

        project.request(.post, authorizeUrl, timeout: 4) { request in
            guard var request = request else {
                return completion(false)
            }

            let body = [ "encryptedOrigin": token.paymentData.base64EncodedString() ]
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = data

            // can't use `Project.perform` here since we have to deal with "204 NO CONTENT" as the "success" response
            let start = Date.timeIntervalSinceReferenceDate
            let session = SnabbleAPI.urlSession()
            let task = session.dataTask(with: request) { data, response, error in
                let elapsed = Date.timeIntervalSinceReferenceDate - start
                let url = request.url?.absoluteString ?? "n/a"
                let method = request.httpMethod ?? ""
                Log.info("\(method) \(url) took \(elapsed)s")

                if let data = data, let raw = String(bytes: data, encoding: .utf8) {
                    Log.info("raw response: \(raw)")
                }

                if let error = error {
                    Log.error("error authorizing apple pay: \(error)")
                    return completion(false)
                }

                if let httpResponse = response as? HTTPURLResponse {
                    let code = httpResponse.statusCode
                    let ok = code >= 200 && code <= 299
                    Log.info("response from authorizaton: \(code)")
                    return completion(ok)
                }

                return completion(false)
            }
            task.resume()
        }
    }
}

// MARK: - country code extraction

extension ApplePayCheckoutViewController {
    private static func getCountryCode(from cart: ShoppingCart) -> String? {
        let project = SnabbleUI.project
        var countryCode: String?
        if let shop = project.shops.first(where: { $0.id == cart.shopId }) {
            countryCode = Self.get2LetterCountryCode(from: shop.countryCode)
        }

        // no country code? fall back to companyAddress.country
        if countryCode == nil, let projectCountry = project.company?.country {
            countryCode = Self.get2LetterCountryCode(from: projectCountry)
        }

        return countryCode
    }

    private static func get2LetterCountryCode(from code: String?) -> String? {
        guard let code = code else {
            return nil
        }

        let identifier = Locale.identifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code ])
        let locale = Locale(identifier: identifier)
        return locale.regionCode
    }

}

// MARK: - PKPaymentAuthorizationViewControllerDelegate

extension ApplePayCheckoutViewController: PKPaymentAuthorizationViewControllerDelegate {
    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        self.authController?.dismiss(animated: true)

        if !authorized {
            super.cancelPayment()
        }
    }

    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        authorized = true
        self.performPayment(with: self.currentProcess, and: payment.token) { success in
            let status: PKPaymentAuthorizationStatus = success ? .success : .failure
            completion(PKPaymentAuthorizationResult(status: status, errors: nil))
        }
    }
}
