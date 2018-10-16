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
        }
    }

    var processRequired: Bool {
        switch self {
        case .cash, .qrCode: return true
        case .encodedCodes: return false
        }
    }

    func processor(_ process: CheckoutProcess?, _ cart: ShoppingCart, _ delegate: PaymentDelegate) -> UIViewController? {
        if self.processRequired && process == nil {
            return nil
        }

        let processor: UIViewController
        switch self {
        case .cash: processor = CashCheckoutViewController(process!, cart, delegate)
        case .qrCode: processor = QRCheckoutViewController(process!, cart, delegate)
        case .encodedCodes: processor = EmbeddedCodesCheckoutViewController(cart, delegate)
        }
        processor.hidesBottomBarWhenPushed = true
        return processor
    }
}

/// Manage the payment process
public class PaymentProcess {
    private(set) var signedCheckoutInfo: SignedCheckoutInfo
    private(set) var cart: ShoppingCart
    private var hudTimer: Timer?
    private weak var delegate: PaymentDelegate!

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
    /// otherwise, directly create the corresponding view controller for the selected payment mehthod
    ///
    /// - Parameter completion: a closure called when the payment method has been determined.
    ///             This is passed a `UIViewController` instance that the caller can present
    public func start(completion: @escaping (UIViewController) -> () ) {
        let info = self.signedCheckoutInfo
        if info.checkoutInfo.paymentMethods.count > 1 {
            let paymentSelection = PaymentMethodSelectionViewController(self)
            completion(paymentSelection)
        } else {
            let method = info.checkoutInfo.paymentMethods[0]
            self.start(method) { viewController in
                completion(viewController)
            }
        }
    }

    func start(_ method: PaymentMethod, completion: @escaping (UIViewController) -> () ) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.startBlurOverlayTimer()

        self.signedCheckoutInfo.createCheckoutProcess(SnabbleUI.project, paymentMethod: method, timeout: 2) { process, error in
            self.hudTimer?.invalidate()
            self.hudTimer = nil
            UIApplication.shared.endIgnoringInteractionEvents()
            self.hideBlurOverlay()
            if let process = process, let processor = method.processor(process, self.cart, self.delegate) {
                completion(processor)
            } else {
                let handled = self.delegate.handlePaymentError(error)
                if !handled {
                    if method == .encodedCodes, let processor = method.processor(nil, self.cart, self.delegate) {
                        // continue anyway
                        completion(processor)
                        self.retryCreatingMissingCheckout()
                    } else {
                        self.delegate.showInfoMessage("Snabble.Payment.errorStarting".localized())
                    }
                }
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
            self.cart.createCheckoutInfo(SnabbleUI.project) { info, _ in
                info?.createCheckoutProcess(SnabbleUI.project, paymentMethod: .encodedCodes) { _,_ in }
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
