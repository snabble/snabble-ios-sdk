//
//  BaseCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//
import UIKit
import SwiftUI
import SnabbleCore
import Combine
import SnabbleAssetProviding

open class BaseCheckViewModel: ObservableObject, CheckViewModel {
    @Published public var checkModel: CheckModel
    @Published public var codeImage: UIImage?
    @Published public var headerImage: UIImage?
    
    public weak var paymentDelegate: PaymentDelegate? {
        didSet {
            checkModel.paymentDelegate = paymentDelegate
        }
    }
    public var idString: String {
        return String(checkModel.checkoutProcess.id.suffix(4))
    }
    private var cancellables = Set<AnyCancellable>()

    public init(checkModel: CheckModel) {
        self.checkModel = checkModel
        self.checkModel.continuation = checkContinuation(_:)
        
        self.checkModel.assetPublisher()
            .sink { [unowned self] image in
                self.headerImage = image
            }
            .store(in: &cancellables)
        updateCodeImage()
    }

    public convenience init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess, paymentDelegate: PaymentDelegate? = nil) {
        let model = CheckModel(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess, paymentDelegate: paymentDelegate)
        self.init(checkModel: model)
    }
    
    // swiftlint:disable:next no_empty_block
    func updateCodeImage() {
    }

    // gatekeeper decision depends on the process' checks as well as the payment and fulfillment status
    func checkContinuation(_ process: CheckoutProcess) -> CheckModel.CheckResult {
        return .rejectCheckout
    }
}

// base class for SupervisorCheckViewController and GatekeeperCheckViewController
open class BaseCheckViewController<Content: View>: UIHostingController<Content>, CheckViewModelProviding, CheckoutProcessing, CheckModelDelegate {
    
    public var viewModel: CheckViewModel?
    
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
    
    public func checkoutRejected(process: SnabbleCore.CheckoutProcess) {
        let reject = SupervisorRejectedViewController(process)
        self.shoppingCart.generateNewUUID()
        reject.delegate = self.paymentDelegate
        self.navigationController?.pushViewController(reject, animated: true)
    }
    
    public func checkoutFinalized(process: SnabbleCore.CheckoutProcess) {
        guard
            let method = process.rawPaymentMethod,
            let checkoutDisplay = method.checkoutDisplayViewController(
                shop: self.shop,
                checkoutProcess: process,
                shoppingCart: self.shoppingCart,
                delegate: self.paymentDelegate)
        else {
            self.paymentDelegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.errorStarting"))
            return
        }
        self.navigationController?.pushViewController(checkoutDisplay, animated: true)
    }
    
    public func checkoutAborted(process: SnabbleCore.CheckoutProcess) {
        if let cartVC = self.navigationController?.viewControllers.first(where: { $0 is ShoppingCartViewController}) {
            self.navigationController?.popToViewController(cartVC, animated: true)
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}
