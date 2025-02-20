//
//  ShoppingCart+PaymentSelection.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

// import SDCAlertView
import SnabbleCore
import SnabbleAssetProviding

protocol PaymentMethodSelectorDelegate: AnyObject {
    func paymentMethodSelector(_ paymentMethodSelector: PaymentMethodSelector, didSelectMethod: RawPaymentMethod?)
}

final class PaymentMethodSelector {
    
    private weak var parentVC: (UIViewController & AnalyticsDelegate)?
    private weak var methodSelectionView: UIView?
    private weak var methodIcon: UIImageView?

    private(set) var methodTap: UITapGestureRecognizer!

    var selectedPayment: Payment? {
        paymentManager.selectedPayment
    }

    private var shoppingCart: ShoppingCart
    weak var delegate: PaymentMethodSelectorDelegate?
    
    let paymentManager: PaymentMethodManager
    
    init(_ parentVC: (UIViewController & AnalyticsDelegate)?,
         _ selectionView: UIView,
         _ methodIcon: UIImageView,
         _ cart: ShoppingCart
    ) {
        self.parentVC = parentVC
        self.methodSelectionView = selectionView
        self.methodIcon = methodIcon

        self.shoppingCart = cart

        self.paymentManager = PaymentMethodManager(project: SnabbleCI.project, paymentConsumer: cart)
        self.paymentManager.delegate = self
        
        self.methodSelectionView?.isHidden = !self.paymentManager.hasMethodsToSelect

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.methodSelectionTapped(_:)))
        self.methodTap = tap
        self.methodSelectionView?.addGestureRecognizer(tap)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdating(_:)), name: .snabbleCartUpdating, object: nil)
    }

    func updateSelectionVisibility() {
        self.paymentManager.updateSelectionVisibility()
        self.methodSelectionView?.isHidden = !self.paymentManager.hasMethodsToSelect
    }

    @objc private func shoppingCartUpdating(_ notification: Notification) {
        self.methodTap.isEnabled = false
    }

    func updateAvailablePaymentMethods() {
        self.methodTap.isEnabled = true

        paymentManager.updateAvailablePaymentMethods()
    }
    
    @objc private func methodSelectionTapped(_ gesture: UITapGestureRecognizer) {
        let sheet = paymentManager.sheetController()
        
        self.parentVC?.present(sheet, animated: true)
    }
}

extension PaymentMethodSelector: PaymentMethodManagerDelegate {
    func paymentMethodManager(didSelectPayment payment: Payment?) {
        let method = payment?.method
        let detail = payment?.detail

        var icon = detail?.icon ?? method?.icon
        
        if method?.dataRequired == true && detail == nil {
           icon = icon?.grayscale()
        }
        if let imageView = methodIcon, let icon {
            UIView.transition(with: imageView, duration: 0.16, options: .transitionCrossDissolve, animations: {
                self.methodIcon?.image = icon
            })

        }

        self.methodTap.isEnabled = true
        delegate?.paymentMethodSelector(self, didSelectMethod: payment?.method)
    }
    
    func paymentMethodManager(didSelectItem item: PaymentMethodItem) {
        guard item.selectable else {
            return
        }
        let method = item.method
        let detail = item.methodDetail

        // if the selected method is missing its detail data, immediately open the edit VC for the method
        if
            detail == nil,
            let parent = parentVC,
            method.isAddingAllowed(showAlertOn: parent) == true,
            let editVC = method.editViewController(with: SnabbleCI.project.id, parent) {
            parent.navigationController?.pushViewController(editVC, animated: true)
        } else if method == .applePay && !ApplePay.canMakePayments(with: SnabbleCI.project.id) {
            ApplePay.openPaymentSetup()
        }
   }
}
