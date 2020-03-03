//
//  PaymentMethod+UI.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

/// map payment methods to icons and the UIViewControllers that implement them
extension PaymentMethod {
    var icon: String {
        switch self {
        case .qrCodePOS: return "SnabbleSDK/payment-method-checkstand"
        case .qrCodeOffline: return "SnabbleSDK/payment-method-checkstand"
        case .deDirectDebit: return "SnabbleSDK/payment-sepa"
        case .visa: return "SnabbleSDK/payment-visa"
        case .mastercard: return "SnabbleSDK/payment-mastercard"
        case .externalBilling:
            switch self.data?.originType {
            case .tegutEmployeeID: return "SnabbleSDK/payment-tegut"
            default: return ""
            }
        case .gatekeeperTerminal: return "SnabbleSDK/payment-card-terminal"
        case .customerCardPOS: return "SnabbleSDK/payment-method-checkstand"
        }
    }

    var dataRequired: Bool {
        switch self {
        case .deDirectDebit, .visa, .mastercard, .externalBilling: return true
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal, .customerCardPOS: return false
        }
    }

    func canStart() -> Bool {
        if !self.dataRequired {
            return true
        } else {
            return self.data != nil
        }
    }

    func processor(_ process: CheckoutProcess?, _ cart: ShoppingCart, _ delegate: PaymentDelegate) -> UIViewController? {
        if !self.rawMethod.offline && process == nil {
            return nil
        }
        guard self.canStart() else {
            return nil
        }

        let processor: UIViewController
        switch self {
        case .qrCodePOS:
            processor = QRCheckoutViewController(process!, cart, delegate)
        case .qrCodeOffline:
            if let codeConfig = SnabbleUI.project.qrCodeConfig {
                processor = EmbeddedCodesCheckoutViewController(process, cart, delegate, codeConfig)
            } else {
                return nil
            }
        case .deDirectDebit, .visa, .mastercard, .externalBilling:
            processor = OnlineCheckoutViewController(process!, cart, delegate)
        case .gatekeeperTerminal:
            processor = TerminalCheckoutViewController(process!, cart, delegate)
        case .customerCardPOS:
            processor = CustomerCardCheckoutViewController(process!, cart, delegate)
        }
        processor.hidesBottomBarWhenPushed = true
        return processor
    }

    public var displayName: String? {
        if let dataName = self.data?.displayName {
            return dataName
        }

        return self.rawMethod.displayName
    }
}

/// Manage the payment process
public final class PaymentProcess {
    let signedCheckoutInfo: SignedCheckoutInfo
    let cart: ShoppingCart
    private var hudTimer: Timer?
    private(set) weak var delegate: PaymentDelegate!

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

    /// start a payment process
    ///
    /// if the checkout allows multiple payment methods, offer a selection
    /// otherwise, directly create the corresponding view controller for the selected payment method
    ///
    /// - Parameters:
    ///   - completion: a closure called when the payment method has been determined.
    ///   - result: the view controller to present for this payment process or the error
    public func start(completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void ) {
        let info = self.signedCheckoutInfo

        let mergedMethods = self.mergePaymentMethodList(info.checkoutInfo.paymentMethods)
        let paymentMethods = self.filterPaymentMethods(mergedMethods)

        switch paymentMethods.count {
        case 0:
            completion(Result.failure(SnabbleError.noPaymentAvailable))
        case 1:
            let method = paymentMethods[0]
            if method.canStart() {
                self.start(method) { result in
                    completion(result)
                }
            } else {
                fallthrough
            }
        default:
            let paymentSelection = PaymentMethodSelectionViewController(self, paymentMethods, self.delegate)
            completion(Result.success(paymentSelection))
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func mergePaymentMethodList(_ methods: [PaymentMethodDescription]) -> [PaymentMethod] {
        let userData = self.getPaymentUserData(methods)
        var result = [PaymentMethod]()
        for method in methods {
            switch method.method {
            case .qrCodePOS: result.append(.qrCodePOS)
            case .qrCodeOffline: result.append(.qrCodeOffline)
            case .gatekeeperTerminal: result.append(.gatekeeperTerminal)
            case .customerCardPOS: result.append(.customerCardPOS)
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
            case .externalBilling:
                let billing = userData.filter { if case .externalBilling = $0 { return true } else { return false } }
                if !billing.isEmpty {
                    result.append(contentsOf: billing.reversed())
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
            case .tegutEmployeeCard:
                let tegut = methods.first {
                    $0.method == .externalBilling && $0.acceptedOriginTypes?.contains(.tegutEmployeeID) == true
                }

                if tegut != nil {
                    results.append(PaymentMethod.externalBilling(detail.data))
                }
            }
        }

        return results
    }

    func start(_ method: PaymentMethod, completion: @escaping (Result<CheckoutProcess, SnabbleError>) -> Void ) {
           self.signedCheckoutInfo.createCheckoutProcess(SnabbleUI.project, paymentMethod: method, timeout: 20) { result in
               completion(result)
           }
       }

    func start(_ method: PaymentMethod, completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void ) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.startBlurOverlayTimer()

        self.signedCheckoutInfo.createCheckoutProcess(SnabbleUI.project, paymentMethod: method, timeout: 20) { result in
            self.hudTimer?.invalidate()
            self.hudTimer = nil
            UIApplication.shared.endIgnoringInteractionEvents()
            self.hideBlurOverlay()
            switch result {
            case .success(let process):
                if let processor = method.processor(process, self.cart, self.delegate) {
                    completion(Result.success(processor))
                } else {
                    self.delegate.showWarningMessage("Snabble.Payment.errorStarting".localized())
                }
            case .failure(let error):
                self.startFailed(method, error, completion)
            }
        }
    }

    private func startFailed(_ method: PaymentMethod, _ error: SnabbleError?, _ completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void ) {
        var handled = false
        if let error = error {
            handled = self.delegate.handlePaymentError(method, error)
        }
        if !handled {
            if method.rawMethod.offline, let processor = method.processor(nil, self.cart, self.delegate) {
                completion(Result.success(processor))
                OfflineCarts.shared.saveCartForLater(self.cart)
            } else {
                self.delegate.showWarningMessage("Snabble.Payment.errorStarting".localized())
            }
        }
    }

    private func startBlurOverlayTimer() {
        self.hudTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
            self.showBlurOverlay()
        }
    }

    func track(_ event: AnalyticsEvent) {
        self.delegate.track(event)
    }

    // MARK: - blur

    private var blurView: UIView?

    private func showBlurOverlay() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.delegate.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.startAnimating()

        blurEffectView.contentView.addSubview(activityIndicator)
        activityIndicator.center = blurEffectView.contentView.center

        self.delegate.view.addSubview(blurEffectView)
        self.blurView = blurEffectView
    }

    private func hideBlurOverlay() {
        self.blurView?.removeFromSuperview()
        self.blurView = nil
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
