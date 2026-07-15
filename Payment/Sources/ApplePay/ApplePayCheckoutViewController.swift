//
//  ApplePayCheckoutViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import PassKit

import SnabbleCore
import SnabbleAssetProviding
import SnabbleTheme
import SnabbleCart

final class ApplePayCheckoutViewController: UIViewController {
    private var authController: UIViewController?
    private let countryCode: String?
    private var authorized = false
    private var poller: PaymentProcessPoller?
    private var applePayStarted = false
    
    private let checkoutProcess: CheckoutProcess
    private let shoppingCart: ShoppingCart
    private let shop: Shop
    weak var delegate: PaymentDelegate?
    
    private var project: Project! {
        shop.project
    }
    
    public init(shop: Shop,
                checkoutProcess: CheckoutProcess,
                cart: ShoppingCart) {
        self.checkoutProcess = checkoutProcess
        self.shoppingCart = cart
        self.shop = shop
        
        // Apple Pay needs the two-letter ISO country code for the payment. Try to extract that from the various contryCode fields we have
        // in `Shop` and `Project.Company`, which may or may not have 3- or 2-letter codes. Oh well...
        self.countryCode = Self.getCountryCode(from: cart)
        
        // super.init(process, cart, delegate)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Apple Pay"
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Guard against re-entry when the Apple Pay sheet is dismissed and viewDidAppear fires again.
        // Must run in viewDidAppear (not viewWillAppear) so the VC is fully in the window hierarchy
        // when embedded as a child inside SwiftUI's ContainerView — presenting from a "detached"
        // view controller corrupts the root presentation and leaves navigationController nil.
        guard !applePayStarted else { return }
        applePayStarted = true

        if let applePayAuth = createApplePayProcessor(for: checkoutProcess) {
            self.authController = applePayAuth
            self.present(applePayAuth, animated: true)
        }
    }
    
    private func createApplePayProcessor(for process: CheckoutProcess) -> UIViewController? {
        guard
            let merchantId = process.paymentPreauthInformation?.merchantID,
            let countryCode = self.countryCode
        else {
            return nil
        }
        
        let decimalDigits = project.decimalDigits
        
        let paymentRequest = PKPaymentRequest()
        if project.paymentMethodDescriptors.contains(where: { descriptor in
            descriptor.id == .applePay && descriptor.providerName == .payone
        }) {
            paymentRequest.requiredBillingContactFields = [.name, .postalAddress]
        }
        
        if project.paymentMethodDescriptors.contains(where: { descriptor in
            descriptor.id == .applePay && descriptor.providerName == .telecash
        }) {
            paymentRequest.applicationData = process.id.data(using: .utf8)
        }
        
        paymentRequest.merchantIdentifier = merchantId
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = process.currency
        paymentRequest.supportedNetworks = ApplePay.paymentNetworks(with: project.id)
        paymentRequest.merchantCapabilities = .threeDSecure
        
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
    private func performPayment(with process: CheckoutProcess,
                                encryptedOrigin: String,
                                paymentNetwork: String?,
                                lastName: String?,
                                isoCountryCode: String?,
                                state: String?,
                                completion: @escaping @Sendable (_ success: Bool) -> Void) {
        guard let authorizeUrl = process.links.authorizePayment?.href else {
            return completion(false)
        }
        
        project.request(.post, authorizeUrl, timeout: 4) { request in
            guard var request = request else {
                return completion(false)
            }
            
            var body = [
                "encryptedOrigin": encryptedOrigin
            ]
            if let network = paymentNetwork {
                body["paymentNetwork"] = network
            }
            if let familyName = lastName {
                body["lastName"] = familyName
            }
            if let isoCountry = isoCountryCode {
                body["countryCode"] = isoCountry
            }
            if let stateValue = state {
                body["state"] = stateValue
            }
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = data
            
            // can't use `Project.perform` here since we have to deal with "204 NO CONTENT" as the "success" response
            let start = Date.timeIntervalSinceReferenceDate
            let session = Snabble.urlSession
            // Capture values before async closure to avoid concurrency warning
            let requestURL = request.url?.absoluteString ?? "n/a"
            let requestMethod = request.httpMethod ?? ""
            let task = session.dataTask(with: request) { data, response, error in
                let elapsed = Date.timeIntervalSinceReferenceDate - start
                Log.info("\(requestMethod) \(requestURL) took \(elapsed)s")
                
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
    
    private func cancelPayment() {
        self.delegate?.track(.paymentCancelled)

        self.checkoutProcess.abort(SnabbleCI.project) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    Snabble.clearInFlightCheckout()
                    self.shoppingCart.generateNewUUID()
                    self.delegate?.checkoutFinished(self.shoppingCart, nil)

                case .failure:
                    let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.Payment.CancelError.title"),
                                                  message: Asset.localizedString(forKey: "Snabble.Payment.CancelError.message"),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - country code extraction

extension ApplePayCheckoutViewController {
    private static func getCountryCode(from cart: ShoppingCart) -> String? {
        let project = SnabbleCI.project
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
        return locale.region?.identifier
    }
    
}

// MARK: - PKPaymentAuthorizationViewControllerDelegate

extension ApplePayCheckoutViewController: PKPaymentAuthorizationViewControllerDelegate {
    nonisolated public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        Task { @MainActor in
            self.authController?.dismiss(animated: true)
            
            if !authorized {
                cancelPayment()
            } else {
                waitForPaymentProcessing()
            }
        }
    }
    
    nonisolated public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        final class CompletionBox: @unchecked Sendable {
            let completion: (PKPaymentAuthorizationResult) -> Void
            init(_ completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
                self.completion = completion
            }
        }
        
        let box = CompletionBox(completion)
        // Extract Sendable values before crossing actor boundary (PKPayment is not Sendable)
        let encryptedOrigin = payment.token.paymentData.base64EncodedString()
        let paymentNetwork = payment.token.paymentMethod.network?.rawValue
        let lastName = payment.billingContact?.name?.familyName
        let isoCountryCode = payment.billingContact?.postalAddress?.isoCountryCode
        let state = payment.billingContact?.postalAddress?.state
        Task { @MainActor in
            authorized = true
            self.performPayment(with: self.checkoutProcess,
                                encryptedOrigin: encryptedOrigin,
                                paymentNetwork: paymentNetwork,
                                lastName: lastName,
                                isoCountryCode: isoCountryCode,
                                state: state) { success in
                let status: PKPaymentAuthorizationStatus = success ? .success : .failure
                box.completion(PKPaymentAuthorizationResult(status: status, errors: nil))
            }
        }
    }
    
    private func waitForPaymentProcessing() {
        let project = SnabbleCI.project
        let poller = PaymentProcessPoller(checkoutProcess, project)
        
        poller.waitFor([.paymentSuccess]) { events in
            if events[.paymentSuccess] != nil {
                Task { @MainActor in
                    self.paymentFinished(poller.updatedProcess)
                }
            }
        }
        
        self.poller = poller
    }
    
    private func paymentFinished(_ checkoutProcess: CheckoutProcess) {
        self.poller = nil

        let paymentDisplay = CheckoutStepsViewController(shop: shop,
                                                         shoppingCart: shoppingCart,
                                                         checkoutProcess: checkoutProcess)
        paymentDisplay.paymentDelegate = delegate
        delegate?.paymentRequiresNavigation(to: paymentDisplay)
    }
}
