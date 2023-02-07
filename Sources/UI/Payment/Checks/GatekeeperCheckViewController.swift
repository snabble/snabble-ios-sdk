//
//  GatekeeperCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

final class GatekeeperViewModel: ObservableObject, CheckViewModel {
    
    @Published var checkModel: CheckModel
    @Published var codeImage: UIImage?
    
    init(checkModel: CheckModel) {
        self.checkModel = checkModel
        self.checkModel.continuation = checkContinuation(_:)
        
        self.codeImage = QRCode.generate(for: self.checkModel.codeContent, scale: 5)
    }
    convenience init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        let model = CheckModel(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess)
        self.init(checkModel: model)
    }

    // gatekeeper decision depends on the process' checks as well as the payment and fulfillment status
    func checkContinuation(_ process: CheckoutProcess) -> CheckModel.CheckResult {
        if process.hasFailedChecks {
            return .rejectCheckout
        }

        // this is necessary because currently the paymentState stays at `.pending`
        // when allocation failures happen
        if process.fulfillmentsAllocationFailed() > 0 {
            return .finalizeCheckout
        }

        // gatekeepers also have to wait until the payment moves to e.g. `.transferred`
        // or `.processing`, e.g. for payments via the physical card readers
        if process.paymentState == .pending {
            return .continuePolling
        }

        if process.allChecksSuccessful {
            return .finalizeCheckout
        }
        return .continuePolling
    }
}

final class GatekeeperCheckViewController: BaseCheckViewController {

    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        super.init()
        
        self.viewModel = GatekeeperViewModel(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess)
        self.viewModel?.checkModel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        text?.text = nil
    }

    override func arrangeLayout() {
        if let iconWrapper = iconWrapper,
           let textWrapper = textWrapper,
           let arrowWrapper = arrowWrapper,
           let idWrapper = idWrapper,
           let codeWrapper = codeWrapper {
            stackView?.addArrangedSubview(iconWrapper)
            stackView?.addArrangedSubview(textWrapper)
            stackView?.addArrangedSubview(arrowWrapper)
            stackView?.addArrangedSubview(codeWrapper)
            stackView?.addArrangedSubview(idWrapper)
        }
    }
}
