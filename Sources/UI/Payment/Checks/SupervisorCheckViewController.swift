//
//  SupervisorCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

final class SupervisorViewModel: ObservableObject, CheckViewModel {
    
    @Published var checkModel: CheckModel
    @Published var codeImage: UIImage?
    
    init(checkModel: CheckModel) {
        self.checkModel = checkModel
        self.checkModel.continuation = checkContinuation(_:)
        
        self.codeImage = PDF417.generate(for: self.checkModel.codeContent, scale: 2)
    }
    
    convenience init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        let model = CheckModel(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess)
        self.init(checkModel: model)
    }
    
    // supervisors are only concerned with checks: if there are failed checks, bail out,
    // and if all checks pass, finalize the checkout
    func checkContinuation(_ process: CheckoutProcess) -> CheckModel.CheckResult {
        if process.hasFailedChecks {
            return .rejectCheckout
        }

        if process.allChecksSuccessful {
            return .finalizeCheckout
        }

        return .continuePolling
    }
}

final class SupervisorCheckViewController: BaseCheckViewController {

    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        super.init()
        
        self.viewModel = SupervisorViewModel(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess)
        self.viewModel?.checkModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func arrangeLayout() {
        if let iconWrapper = iconWrapper,
           let textWrapper = textWrapper,
           let idWrapper = idWrapper,
           let codeWrapper = codeWrapper {
            stackView?.addArrangedSubview(iconWrapper)
            stackView?.addArrangedSubview(textWrapper)
            stackView?.addArrangedSubview(codeWrapper)
            stackView?.addArrangedSubview(idWrapper)
        }
    }
}
