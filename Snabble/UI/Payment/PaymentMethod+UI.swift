//
//  PaymentMethod+UI.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

/// map payment methods to icons and the UIViewControllers that implement them
extension PaymentMethod {
    var icon: String {
        switch self {
        case .cash: return "payment-method-cash"
        case .qrCode: return "payment-method-checkstand"
        case .encodedCodes: return "payment-method-checkstand"
        case .teleCashDeDirectDebit: return "payment-sepa"
        }
    }

    var processRequired: Bool {
        switch self {
        case .encodedCodes: return false
        default: return true
        }
    }

    var dataRequired: Bool {
        switch self {
        case .teleCashDeDirectDebit: return true
        default: return false
        }
    }

    func processor(_ process: CheckoutProcess?, _ method: PaymentMethod, _ cart: ShoppingCart, _ delegate: PaymentDelegate) -> UIViewController? {
        if self.processRequired && process == nil {
            return nil
        }
        if self.dataRequired && method.data == nil {
            return nil
        }

        let processor: UIViewController
        switch self {
        case .cash: processor = CashCheckoutViewController(process!, cart, delegate)
        case .qrCode: processor = QRCheckoutViewController(process!, cart, delegate)
        case .encodedCodes: processor = EmbeddedCodesCheckoutViewController(process, cart, delegate)
        case .teleCashDeDirectDebit: processor = SepaCheckoutViewController(process!, method.data!, cart, delegate)
        }
        processor.hidesBottomBarWhenPushed = true
        return processor
    }
}

/// Manage the payment process
public final class PaymentProcess {
    private(set) var signedCheckoutInfo: SignedCheckoutInfo
    private(set) var cart: ShoppingCart
    private var hudTimer: Timer?
    weak var delegate: PaymentDelegate!

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
    public func start(completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> () ) {
        let info = self.signedCheckoutInfo

        let paymentMethods = self.mergePaymentMethodList(info.checkoutInfo.paymentMethods)

        if paymentMethods.count > 1 {
            let paymentSelection = PaymentMethodSelectionViewController(self, paymentMethods)
            completion(Result.success(paymentSelection))
        } else {
            let method = paymentMethods[0]
            self.start(method) { result in
                completion(result)
            }
        }
    }

    private func mergePaymentMethodList(_ methods: [RawPaymentMethod]) -> [PaymentMethod] {
        let userData = self.delegate.getPaymentData()
        var result = [PaymentMethod]()
        for method in methods {
            switch method {
            case .cash: result.append(.cash)
            case .encodedCodes: result.append(.encodedCodes)
            case .qrCode: result.append(.qrCode)
            case .teleCashDeDirectDebit:
                let telecash = userData.filter { if case .teleCashDeDirectDebit = $0 { return true } else { return false } }
                result.append(contentsOf: telecash.reversed())
            }
        }

        return result
    }

    func start(_ method: PaymentMethod, completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> () ) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.startBlurOverlayTimer()

        self.signedCheckoutInfo.createCheckoutProcess(SnabbleUI.project, paymentMethod: method, timeout: 20) { result in
            self.hudTimer?.invalidate()
            self.hudTimer = nil
            UIApplication.shared.endIgnoringInteractionEvents()
            self.hideBlurOverlay()
            switch result {
            case .success(let process):
                if let processor = method.processor(process, method, self.cart, self.delegate) {
                    completion(Result.success(processor))
                } else {
                    self.startFailed(method, nil, completion)
                }
            case .failure(let error):
                self.startFailed(method, error, completion)
                let handled = self.delegate.handlePaymentError(error)
                if !handled {
                    if method.rawMethod == .encodedCodes, let processor = method.processor(nil, method, self.cart, self.delegate) {
                        // continue anyway
                        completion(Result.success(processor))
                        self.retryCreatingMissingCheckout()
                    } else {
                        self.delegate.showWarningMessage("Snabble.Payment.errorStarting".localized())
                    }
                }
            }
        }
    }

    private func startFailed(_ method: PaymentMethod, _ error: SnabbleError?, _ completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> () ) {
        var handled = false
        if let error = error {
            handled = self.delegate.handlePaymentError(error)
        }
        if !handled {
            if method.rawMethod == .encodedCodes, let processor = method.processor(nil, method, self.cart, self.delegate) {
                // continue anyway
                completion(Result.success(processor))
                self.retryCreatingMissingCheckout()
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

    // retry creating the checkout info / checkout process that is potentially missing
    private func retryCreatingMissingCheckout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.cart.createCheckoutInfo(SnabbleUI.project) { result in
                if case Result.success(let info) = result {
                    info.createCheckoutProcess(SnabbleUI.project, paymentMethod: .encodedCodes) { _ in }
                }
            }
        }
    }

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
