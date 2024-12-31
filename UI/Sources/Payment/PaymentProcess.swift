//
//  PaymentProcess.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

import SnabbleCore
import SnabbleAssetProviding

/// Manage the payment process
public final class PaymentProcess {
    let signedCheckoutInfo: SignedCheckoutInfo
    let cart: ShoppingCart
    let shop: Shop
    private weak var hudTimer: Timer?
    public weak var paymentDelegate: PaymentDelegate?

    /// create a payment process
    ///
    /// - Parameters:
    ///   - signedCheckoutInfo: the checkout info for this process
    ///   - cart: the cart for this process
    ///   - delegate: the `PaymentDelegate` to use
    public init(_ signedCheckoutInfo: SignedCheckoutInfo, _ cart: ShoppingCart, shop: Shop) {
        self.signedCheckoutInfo = signedCheckoutInfo
        self.cart = cart
        self.shop = shop
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
            case .giropayOneKlick:
                let giropay = userData.filter { if case .giropayOneKlick = $0 { return true } else { return false } }
                if !giropay.isEmpty {
                    result.append(contentsOf: giropay.reversed())
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
            case .sepa, .payoneSepa:
                let useDirectDebit = methods.first { $0.method == .deDirectDebit } != nil
                if useDirectDebit {
                    let debitData = PaymentMethod.deDirectDebit(detail.data)
                    results.append(debitData)
                }
            case .tegutEmployeeCard:
                let tegut = methods.first {
                    $0.method == .externalBilling && $0.acceptedOriginTypes?.contains(.tegutEmployeeID) == true
                }
                if tegut != nil {
                    results.append(PaymentMethod.externalBilling(detail.data))
                }
            case .giropayAuthorization:
                let useGiropay = methods.first { $0.method == .giropayOneKlick } != nil
                if useGiropay {
                    let useGiropay = PaymentMethod.giropayOneKlick(detail.data)
                    results.append(useGiropay)
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

            case .teleCashCreditCard(let ccData as BrandedCreditCard),
                    .datatransCardAlias(let ccData as BrandedCreditCard),
                    .payoneCreditCard(let ccData as BrandedCreditCard):
                let data = detail.data
                let useVisa = methods.first { $0.method == .creditCardVisa } != nil
                if useVisa && ccData.brand == .visa {
                    let visa = PaymentMethod.visa(data)
                    results.append(visa)
                }

                let useMastercard = methods.first { $0.method == .creditCardMastercard } != nil
                if useMastercard && ccData.brand == .mastercard {
                    let mc = PaymentMethod.mastercard(data)
                    results.append(mc)
                }

                let useAmex = methods.first { $0.method == .creditCardAmericanExpress } != nil
                if useAmex && ccData.brand == .amex {
                    let amex = PaymentMethod.americanExpress(data)
                    results.append(amex)
                }
            case .invoiceByLogin:
                let invoice = methods.first {
                    $0.method == .externalBilling && $0.acceptedOriginTypes?.contains(.contactPersonCredentials) == true
                }
                if invoice != nil {
                    results.append(PaymentMethod.externalBilling(detail.data))
                }

            }
        }

        return results
    }

    private func startFailed(_ method: PaymentMethod, shop: Shop, _ error: SnabbleError?, _ completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void ) {
        var handled = false
        if let error = error {
            handled = self.paymentDelegate?.handlePaymentError(method, error) ?? false
        }
        if !handled {
            let checkoutDisplay = method.rawMethod.checkoutDisplayViewController(shop: shop, checkoutProcess: nil, shoppingCart: self.cart, delegate: self.paymentDelegate)
            // if method.rawMethod.offline, let processor = method.processor(nil, shop: shop, self.cart, self.paymentDelegate) {
            if method.rawMethod.offline, let display = checkoutDisplay {
                completion(.success(display))
                OfflineCarts.shared.saveCartForLater(self.cart)
            } else {
                self.paymentDelegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.errorStarting"))
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
        self.paymentDelegate?.track(event)
    }

    // MARK: - blur

    private var blurView: UIView?

    private func showBlurOverlay() {
        guard let view = self.paymentDelegate?.view else {
            return
        }

        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let activityIndicator = UIActivityIndicatorView(style: .large)
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

    /// start a payment process with the given payment method
    ///
    /// - Parameters:
    ///   - rawMethod: the payment method to use
    ///   - detail: the details for that payment method (e.g., the encrypted IBAN for SEPA)
    ///   - completion: a closure called when the payment method has been determined.
    ///   - result: the view controller to present for this payment process or the error
    public func start(_ rawMethod: RawPaymentMethod, _ detail: PaymentMethodDetail?, completion: @escaping (_ result: Result<UIViewController, SnabbleError>) -> Void) {
        guard
            let method = PaymentMethod.make(rawMethod, detail),
            method.canStart()
        else {
            return completion(Result.failure(.noRequest))
        }

        UIApplication.shared.sceneKeyWindow?.isUserInteractionEnabled = false
        self.startBlurOverlayTimer()

        let project = shop.project ?? .none
        let id = self.cart.uuid
        
        self.signedCheckoutInfo.createCheckoutProcess(project, id: id, paymentMethod: method, timeout: Self.createTimeout) { result in
            self.hudTimer?.invalidate()
            UIApplication.shared.sceneKeyWindow?.isUserInteractionEnabled = true
            self.hideBlurOverlay()
            
            func checkoutProcess(process: CheckoutProcess) {
                
                // if process contains voucherInformation where state == .redeemingFailed,
                // filter cart.vouchers containing these IDs
                // and return the VoucherAlertViewController
                if let voucherIds = process.voucherInformation?.filter( { $0.state == .redeemingFailed }).compactMap(\.refersTo) {
                    let vouchers = self.cart.vouchers.filter( { voucherIds.contains($0.uuid) })
                    if !vouchers.isEmpty {
                        let voucherAlert = VoucherAlertViewController(vouchers: vouchers, shoppingCart: self.cart)
                        completion(.success(voucherAlert))
                        return
                    }
                }
                    
                let checkoutVC = Self.checkoutViewController(for: process,
                                                             shop: self.shop,
                                                             cart: self.cart,
                                                             paymentDelegate: self.paymentDelegate)
                
                if let viewController = checkoutVC {
                    completion(.success(viewController))
                } else {
                    self.paymentDelegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.errorStarting"))
                }
            }
            
            func errorHandler(error: SnabbleError) {
                if !error.isUrlError(.timedOut) {
                    self.cart.generateNewUUID()
                }
                self.startFailed(method, shop: self.shop, error, completion)
            }
                        
            switch result.result {
            case .success(let process):
                Snabble.storeInFlightCheckout(url: process.links._self.href,
                                              shop: self.shop,
                                              cart: self.cart)
                checkoutProcess(process: process)

            case .failure(let error):
                errorHandler(error: error)
            }
        }
    }

    static func checkoutViewController(for process: CheckoutProcess,
                                       shop: Shop,
                                       cart: ShoppingCart,
                                       paymentDelegate: PaymentDelegate?) -> UIViewController? {
        guard let rawMethod = RawPaymentMethod(rawValue: process.paymentMethod) else {
            return nil
        }
        guard process.paymentState != .successful || process.paymentState != .failed else {
            let checkoutStepsViewController = CheckoutStepsViewController(
                shop: shop,
                shoppingCart: cart,
                checkoutProcess: process
            )
            checkoutStepsViewController.paymentDelegate = paymentDelegate
            return checkoutStepsViewController
        }
        switch process.routingTarget {
        case .none:
            let checkoutDisplay = rawMethod.checkoutDisplayViewController(shop: shop,
                                                                          checkoutProcess: process,
                                                                          shoppingCart: cart,
                                                                          delegate: paymentDelegate)

            if let display = checkoutDisplay {
                return display
            } else {
                return nil
            }
        case .supervisor:
            let model = SupervisorViewModel(shop: shop, shoppingCart: cart, checkoutProcess: process, paymentDelegate: paymentDelegate)
            let supervisor = SupervisorCheckViewController(model: model)
            return supervisor
        case .gatekeeper:
            let model = GatekeeperViewModel(shop: shop, shoppingCart: cart, checkoutProcess: process, paymentDelegate: paymentDelegate)
            if let object = Gatekeeper.gatekeeper(viewModel: model) {
                return object
            } else {
                let gatekeeper = GatekeeperCheckViewController(model: model)
                return gatekeeper
            }
        }
    }
}
