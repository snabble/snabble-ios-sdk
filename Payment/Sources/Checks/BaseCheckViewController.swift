//
//  BaseCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//
import UIKit
import SwiftUI

import SnabbleCore
import SnabbleAssetProviding
import SnabbleCart

@Observable
@MainActor
open class BaseCheckViewModel: CheckViewModel, @unchecked Sendable {
    public var checkModel: CheckModel
    public var codeImage: UIImage?
    public var headerImage: UIImage?
    
    public weak var paymentDelegate: PaymentDelegate? {
        didSet {
            checkModel.paymentDelegate = paymentDelegate
        }
    }
    public var idString: String {
        return String(checkModel.checkoutProcess.id.suffix(4))
    }

    public init(checkModel: CheckModel) {
        self.checkModel = checkModel
        self.checkModel.continuation = checkContinuation(_:)
        
        Task {
            self.headerImage = await self.checkModel.loadAsset()
        }
        updateCodeImage()
    }

    public convenience init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess, paymentDelegate: PaymentDelegate? = nil) {
        let model = CheckModel(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess, paymentDelegate: paymentDelegate)
        self.init(checkModel: model)
    }

    func updateCodeImage() {
    }

    // gatekeeper decision depends on the process' checks as well as the payment and fulfillment status
    func checkContinuation(_ process: CheckoutProcess) -> CheckModel.CheckResult {
        return .rejectCheckout
    }
}

// base class for SupervisorCheckViewController and GatekeeperCheckViewController
open class BaseCheckViewController<Content: View>: UIHostingController<Content>, CheckViewModelProviding, CheckoutProcessing, CheckModelDelegate {
    
    nonisolated(unsafe) public var viewModel: CheckViewModel?
    
    public init(model: CheckViewModel, rootView: Content) {
        super.init(rootView: rootView)
        self.viewModel = model
        self.checkModel.delegate = self
        
        self.hidesBottomBarWhenPushed = true
        title = Asset.localizedString(forKey: "Snabble.Payment.confirm")
    }
    
    @MainActor required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var initialBrightness: CGFloat = 0.0
    
    open override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        print("willMove")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.paymentDelegate?.track(.brightnessIncreased)
        }
        UIApplication.shared.isIdleTimerDisabled = true
        
        checkModel.startCheck()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

@MainActor
extension CheckViewModelProviding where Self: UIViewController {
    var checkModel: CheckModel {
        guard let checkModel = viewModel?.checkModel else {
            fatalError("no viewModel set")
        }
        return checkModel
    }
    public var paymentDelegate: PaymentDelegate? {
        return self.checkModel.paymentDelegate
    }
    public var shoppingCart: SnabbleCore.ShoppingCart {
        self.checkModel.shoppingCart
    }
    public var shop: SnabbleCore.Shop {
        self.checkModel.shop
    }
    public var checkoutProcess: CheckoutProcess {
        self.checkModel.checkoutProcess
    }
    
    nonisolated public func checkoutRejected(process: SnabbleCore.CheckoutProcess) {
        Task { @MainActor in
            let reject = SupervisorRejectedViewController(process)
            self.shoppingCart.generateNewUUID()
            reject.delegate = self.paymentDelegate
            self.navigationController?.pushViewController(reject, animated: true)
        }
    }

    nonisolated public func checkoutFinalized(process: SnabbleCore.CheckoutProcess) {
        Task { @MainActor in
            // For online payments and other methods that don't need a follow-up screen,
            // call checkoutFinished directly
            if let method = process.rawPaymentMethod {
                // Try to get a checkout display view controller
                if let checkoutDisplay = method.checkoutDisplayViewController(
                    shop: self.shop,
                    checkoutProcess: process,
                    shoppingCart: self.shoppingCart,
                    delegate: self.paymentDelegate) {
                    // Push the follow-up screen (e.g., for QR codes, Apple Pay)
                    self.navigationController?.pushViewController(checkoutDisplay, animated: true)
                } else {
                    // No follow-up screen needed, notify delegate that checkout is finished
                    // The delegate is responsible for dismissing the navigation
                    self.paymentDelegate?.checkoutFinished(self.shoppingCart, process)
                }
            } else {
                self.paymentDelegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.errorStarting"))
            }
        }
    }

    nonisolated public func checkoutAborted(process: SnabbleCore.CheckoutProcess) {
        Task { @MainActor in
            // Hack for VR-iOS to navigate to ShoppingView
            if Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String == "de.vr.quartier",
               let viewController = navigationController?.viewControllers.safelyAccessElement(at: 1) {
                navigationController?.popToViewController(viewController, animated: true)
            }
            // Hack ended
            // FIXME: ShoppingCartViewController
            else if let cartVC = self.navigationController?.viewControllers.first(where: { $0 is ShoppingCartViewController }) {
                self.navigationController?.popToViewController(cartVC, animated: true)
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

private extension Array {
    func safelyAccessElement(at index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }

}
