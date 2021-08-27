//
//  PaymentProcess.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

/// Manage the payment process
public final class PaymentProcess {
    let signedCheckoutInfo: SignedCheckoutInfo
    let cart: ShoppingCart
    private weak var hudTimer: Timer?
    private weak var delegate: PaymentDelegate?

    /// create a payment process
    ///
    /// - Parameters:
    ///   - signedCheckoutInfo: the checkout info for this process
    ///   - cart: the cart for this process
    ///   - delegate: the `PaymentDelegate` to use
    public init(_ signedCheckoutInfo: SignedCheckoutInfo, _ cart: ShoppingCart, delegate: PaymentDelegate) {
        self.signedCheckoutInfo = signedCheckoutInfo
        self.cart = cart
        self.delegate = delegate
    }

    func mergePaymentMethodList(_ methods: [PaymentMethodDescription]) -> [PaymentMethod] {
        let userData = self.getPaymentUserData(methods)
        var result = [PaymentMethod]()
        for method in methods {
            switch method.method {
            case .qrCodePOS: result.append(.qrCodePOS)
            case .qrCodeOffline: result.append(.qrCodeOffline)
            case .gatekeeperTerminal: result.append(.gatekeeperTerminal)
            case .customerCardPOS: result.append(.customerCardPOS)
            case .applePay: result.append(.applePay)
            case .deDirectDebit:
                let sepa = userData.filter { if case .deDirectDebit = $0 { return true } else { return false } }
                if !sepa.isEmpty {
                    result.append(contentsOf: sepa.reversed())
                } else {
                    result.append(.deDirectDebit(nil))
                }
            case .creditCardVisa:
                let visa = userData.filter { if case .visa = $0 { return true } else { return false } }
                if !visa.isEmpty {
                    result.append(contentsOf: visa.reversed())
                } else {
                    result.append(.visa(nil))
                }
            case .creditCardMastercard:
                let mc = userData.filter { if case .mastercard = $0 { return true } else { return false } }
                if !mc.isEmpty {
                    result.append(contentsOf: mc.reversed())
                } else {
                    result.append(.mastercard(nil))
                }
            case .creditCardAmericanExpress:
                let amex = userData.filter { if case .americanExpress = $0 { return true } else { return false } }
                if !amex.isEmpty {
                    result.append(contentsOf: amex.reversed())
                } else {
                    result.append(.americanExpress(nil))
                }
            case .externalBilling:
                let billing = userData.filter { if case .externalBilling = $0 { return true } else { return false } }
                if !billing.isEmpty {
                    result.append(contentsOf: billing.reversed())
                }
            case .paydirektOneKlick:
                let paydirekt = userData.filter { if case .paydirektOneKlick = $0 { return true } else { return false } }
                if !paydirekt.isEmpty {
                    result.append(contentsOf: paydirekt.reversed())
                }
            case .twint:
                let twint = userData.filter { if case .twint = $0 { return true } else { return false } }
                if !twint.isEmpty {
                    result.append(contentsOf: twint.reversed())
                }
            case .postFinanceCard:
                let postFinanceCard = userData.filter { if case .postFinanceCard = $0 { return true } else { return false } }
                if !postFinanceCard.isEmpty {
                    result.append(contentsOf: postFinanceCard.reversed())
                }
            }
        }

        return result.reversed()
    }

    // filter payment methods: if there is at least one online payment method with data, don't show other incomplete online methods
    func filterPaymentMethods(_ methods: [PaymentMethod]) -> [PaymentMethod] {
        let onlineComplete = methods.filter { !$0.rawMethod.offline && $0.data != nil }
        if onlineComplete.isEmpty {
            return methods
        }

        // remove all incomplete online methods
        var methods = methods
        for (index, method) in methods.enumerated().reversed() {
            if !method.rawMethod.offline && method.dataRequired && method.data == nil {
                methods.remove(at: index)
            }
        }
        return methods
    }

    private func getPaymentUserData(_ methods: [PaymentMethodDescription]) -> [PaymentMethod] {
        var results = [PaymentMethod]()

        // check the registered payment methods
        let details = PaymentMethodDetails.read()
        for detail in details {
            switch detail.methodData {
            case .sepa:
                let useDirectDebit = methods.first { $0.method == .deDirectDebit } != nil
                if useDirectDebit {
                    let telecash = PaymentMethod.deDirectDebit(detail.data)
                    results.append(telecash)
                }
            case .creditcard(let creditcardData):
                let data = detail.data
                let useVisa = methods.first { $0.method == .creditCardVisa } != nil
                if useVisa && creditcardData.brand == .visa {
                    let visa = PaymentMethod.visa(data)
                    results.append(visa)
                }

                let useMastercard = methods.first { $0.method == .creditCardMastercard } != nil
                if useMastercard && creditcardData.brand == .mastercard {
                    let mc = PaymentMethod.mastercard(data)
                    results.append(mc)
                }

                let useAmex = methods.first { $0.method == .creditCardAmericanExpress } != nil
                if useAmex && creditcardData.brand == .amex {
                    let amex = PaymentMethod.americanExpress(data)
                    results.append(amex)
                }
            case .tegutEmployeeCard:
                let tegut = methods.first {
                    $0.method == .externalBilling && $0.acceptedOriginTypes?.contains(.tegutEmployeeID) == true
                }
                if tegut != nil {
                    results.append(PaymentMethod.externalBilling(detail.data))
                }
            case .paydirektAuthorization:
                let usePaydirekt = methods.first { $0.method == .paydirektOneKlick } != nil
                if usePaydirekt {
                    let paydirekt = PaymentMethod.paydirektOneKlick(detail.data)
                    results.append(paydirekt)
                }
            case .datatransAlias(let datatransData):
                let data = detail.data
                let useTwint = methods.first { $0.method == .twint } != nil
                if useTwint && datatransData.method == .twint {
                    let twint = PaymentMethod.twint(data)
                    results.append(twint)
                }

                let usePostFinanceCard = methods.first { $0.method == .postFinanceCard } != nil
                if usePostFinanceCard && datatransData.method == .postFinanceCard {
                    let postFinanceCard = PaymentMethod.postFinanceCard(data)
                    results.append(postFinanceCard)
                }
            case .datatransCardAlias(let datatransData):
                let data = detail.data
                let useVisa = methods.first { $0.method == .creditCardVisa } != nil
                if useVisa && datatransData.brand == .visa {
                    let visa = PaymentMethod.visa(data)
                    results.append(visa)
                }

                let useMastercard = methods.first { $0.method == .creditCardMastercard } != nil
                if useMastercard && datatransData.brand == .mastercard {
                    let mc = PaymentMethod.mastercard(data)
                    results.append(mc)
                }

                let useAmex = methods.first { $0.method == .creditCardAmericanExpress } != nil
                if useAmex && datatransData.brand == .amex {
                    let amex = PaymentMethod.americanExpress(data)
                    results.append(amex)
                }

            }
        }

        return results
    }

    private func startFailed(_ method: PaymentMethod, _ error: SnabbleError?, _ completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void ) {
        var handled = false
        if let error = error {
            handled = self.delegate?.handlePaymentError(method, error) ?? false
        }
        if !handled {
            if method.rawMethod.offline, let processor = method.processor(nil, nil, self.cart, self.delegate) {
                completion(.success(processor))
                OfflineCarts.shared.saveCartForLater(self.cart)
            } else {
                self.delegate?.showWarningMessage(L10n.Snabble.Payment.errorStarting)
            }
        }
    }

    private func startBlurOverlayTimer() {
        self.hudTimer?.invalidate()
        self.hudTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
            self.showBlurOverlay()
        }
    }

    func track(_ event: AnalyticsEvent) {
        self.delegate?.track(event)
    }

    // MARK: - blur

    private var blurView: UIView?

    private func showBlurOverlay() {
        guard let view = self.delegate?.view else {
            return
        }

        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.startAnimating()

        blurEffectView.contentView.addSubview(activityIndicator)
        activityIndicator.center = blurEffectView.contentView.center

        view.addSubview(blurEffectView)
        self.blurView = blurEffectView
    }

    private func hideBlurOverlay() {
        self.blurView?.removeFromSuperview()
        self.blurView = nil
    }
}

// MARK: - start payment
extension PaymentProcess {
    private static let createTimeout: TimeInterval = 25

    public func start(_ method: PaymentMethod, completion: @escaping (RawResult<CheckoutProcess, SnabbleError>) -> Void ) {
        let project = SnabbleUI.project
        let id = self.cart.uuid
        self.signedCheckoutInfo.createCheckoutProcess(project, id: id, paymentMethod: method, timeout: Self.createTimeout) { result in
            switch result.result {
            case .success(let process):
                let checker = CheckoutChecks(process)
                let stopProcess = checker.handleChecks()
                if stopProcess {
                    return
                }
            case .failure(let error):
                if error != .timedOut {
                    self.cart.generateNewUUID()
                }
            }
            completion(result)
        }
    }

    /// start a payment process with the given payment method
    ///
    /// - Parameters:
    ///   - rawMethod: the payment method to use
    ///   - detail: the details for that payment method (e.g., the encrypted IBAN for SEPA)
    ///   - completion: a closure called when the payment method has been determined.
    ///   - result: the view controller to present for this payment process or the error
    public func start(_ rawMethod: RawPaymentMethod, _ detail: PaymentMethodDetail?, completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void ) {
        guard
            let method = PaymentMethod.make(rawMethod, detail),
            method.canStart()
        else {
            return completion(Result.failure(.noPaymentAvailable))
        }

        self.start(method, completion)
    }

    private func start(_ method: PaymentMethod, _ completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void ) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.startBlurOverlayTimer()

        let project = SnabbleUI.project
        let id = self.cart.uuid
        self.signedCheckoutInfo.createCheckoutProcess(project, id: id, paymentMethod: method, timeout: Self.createTimeout) { result in
            self.hudTimer?.invalidate()
            UIApplication.shared.endIgnoringInteractionEvents()
            self.hideBlurOverlay()
            switch result.result {
            case .success(let process):
                let checker = CheckoutChecks(process)

                let stopProcess = checker.handleChecks()
                if stopProcess {
                    process.abort(project) { _ in }
                    self.cart.generateNewUUID()
                    return
                }

                if let processor = method.processor(process, result.rawJson, self.cart, self.delegate) {
                    completion(.success(processor))
                } else {
                    self.delegate?.showWarningMessage(L10n.Snabble.Payment.errorStarting)
                }
            case .failure(let error):
                if error != .timedOut {
                    self.cart.generateNewUUID()
                }
                self.startFailed(method, error, completion)
            }
        }
    }
}

// stuff that's only used by the RN wrapper
extension PaymentProcess: ReactNativeWrapper {
    public func getPaymentMethods() -> [PaymentMethod] {
        let info = self.signedCheckoutInfo
        let mergedMethods = self.mergePaymentMethodList(info.checkoutInfo.paymentMethods)
        let paymentMethods = self.filterPaymentMethods(mergedMethods)

        return paymentMethods
    }
}
