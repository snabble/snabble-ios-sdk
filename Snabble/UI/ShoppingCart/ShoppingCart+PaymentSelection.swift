//
//  ShoppingCart+PaymentSelection.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SDCAlertView

private struct PaymentMethodAction {
    let title: NSAttributedString
    let icon: UIImage?
    let method: RawPaymentMethod
    let methodDetail: PaymentMethodDetail?
    let selectable: Bool
    let active: Bool

    init(_ title: NSAttributedString, _ method: RawPaymentMethod, _ methodDetail: PaymentMethodDetail?, selectable: Bool, active: Bool) {
        self.title = title
        self.method = method
        self.methodDetail = methodDetail
        self.icon = methodDetail?.icon ?? method.icon
        self.selectable = selectable
        self.active = active
    }
}

final class PaymentMethodSelector {
    private weak var parentVC: (UIViewController & AnalyticsDelegate)?
    private var methodSelectionView: UIView
    private var methodIcon: UIImageView
    private var methodSpinner: UIActivityIndicatorView

    private(set) var methodTap: UITapGestureRecognizer!

    weak var paymentMethodNavigationDelegate: PaymentMethodNavigationDelegate?

    private(set) var selectedPaymentMethod: RawPaymentMethod?
    private(set) var selectedPaymentDetail: PaymentMethodDetail?
    private var shoppingCart: ShoppingCart

    init(_ parentVC: UIViewController & AnalyticsDelegate,
         _ selectionView: UIView,
         _ methodIcon: UIImageView,
         _ spinner: UIActivityIndicatorView,
         _ cart: ShoppingCart
    ) {
        self.parentVC = parentVC
        self.methodSelectionView = selectionView
        self.methodIcon = methodIcon
        self.methodSpinner = spinner
        self.shoppingCart = cart

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.methodSelectionTapped(_:)))
        self.methodTap = tap
        self.methodSelectionView.addGestureRecognizer(tap)

        if #available(iOS 13.0, *) {
            self.methodSpinner.style = .medium
        }

        self.updateSelectionVisibility()
        self.setDefaultPaymentMethod()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdating(_:)), name: .snabbleCartUpdating, object: nil)
        _ = nc.addObserver(forName: .snabblePaymentMethodAdded, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let detail = notification.userInfo?["detail"] as? PaymentMethodDetail else {
                return
            }

            self?.selectMethodIfValid(detail)
        }

        _ = nc.addObserver(forName: .snabblePaymentMethodDeleted, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.selectMethodIfValid()
        }
    }

    func updateSelectionVisibility() {
        // hide selection if the project only has one method and we have no payment method data
        let details = PaymentMethodDetails.read()
        let hidden = SnabbleUI.project.paymentMethods.count < 2 && details.isEmpty
        self.methodSelectionView.isHidden = hidden

        if let selectedMethod = self.selectedPaymentMethod, let selectedDetail = self.selectedPaymentDetail {
            // check if the selected method is still valid
            let method = details.first { $0 == selectedDetail }
            if method != nil {
                assert(method?.rawMethod == selectedMethod)
                return
            }
        }

        // no method selected, or method no longer valid: select a new default
        self.setDefaultPaymentMethod()
    }

    private func selectMethodIfValid(_ detail: PaymentMethodDetail? = nil) {
        if let detail = detail {
            // method was added, check if we can use it
            let ok = self.shoppingCart.paymentMethods?.contains { $0.method == detail.rawMethod }
            if ok == true {
                self.setSelectedPayment(detail.rawMethod, detail: detail)
            }
        } else {
            // method was deleted, check if it was the selected one
            if let selectedDetail = self.selectedPaymentDetail {
                self.selectedPaymentDetail = nil
                self.selectedPaymentMethod = nil
                let allMethods = PaymentMethodDetails.read()
                if allMethods.firstIndex(of: selectedDetail) == nil {
                    self.setDefaultPaymentMethod()
                }
            }
        }
    }

    @objc private func shoppingCartUpdating(_ notification: Notification) {
        self.methodTap?.isEnabled = false
    }

    func updateAvailablePaymentMethods() {
        self.methodTap?.isEnabled = true

        let paymentMethods = self.shoppingCart.paymentMethods ?? []
        let found = paymentMethods.contains { $0.method == self.selectedPaymentMethod }
        if !found {
            self.setDefaultPaymentMethod()
        } else {
            self.setSelectedPayment(self.selectedPaymentMethod, detail: self.selectedPaymentDetail)
        }
    }

    private func setSelectedPayment(_ method: RawPaymentMethod?, detail: PaymentMethodDetail?) {
        self.selectedPaymentMethod = method
        self.selectedPaymentDetail = detail

        let icon = detail?.icon ?? method?.icon
        self.methodIcon.image = icon
        if method?.dataRequired == true && detail == nil {
            self.methodIcon.image = icon?.grayscale()
        }
        self.methodTap?.isEnabled = true
        self.methodSpinner.stopAnimating()
        self.methodTap.isEnabled = true
    }

    private func setDefaultPaymentMethod() {
        let userMethods = PaymentMethodDetails.read()

        let projectMethods = SnabbleUI.project.paymentMethods
        let cartMethods = self.shoppingCart.paymentMethods?.map { $0.method } ?? []
        let availableMethods = cartMethods.isEmpty ? projectMethods : cartMethods

        // prefer in-app payment methods like SEPA or CC
        for method in RawPaymentMethod.orderedMethods {
            let found = availableMethods.contains(method)
            let userMethod = userMethods.first { $0.rawMethod == method }
            if found, let userMethod = userMethod {
                self.setSelectedPayment(method, detail: userMethod)
                return
            }
        }

        // prefer in-app payment methods like SEPA or CC, even if we have no user data yet
        for method in RawPaymentMethod.preferredOnlineMethods {
            if availableMethods.contains(method) {
                self.setSelectedPayment(method, detail: nil)
                return
            }
        }

        let fallbackMethods: [RawPaymentMethod] = [ .gatekeeperTerminal, .qrCodeOffline, .qrCodePOS, .customerCardPOS ]

        // check if one of the fallbacks matches the cart
        for method in fallbackMethods {
            if availableMethods.contains(method) {
                self.setSelectedPayment(method, detail: nil)
                return
            }
        }

        // check if one of the fallbacks matches the project
        for fallback in fallbackMethods {
            if projectMethods.contains(fallback) {
                self.setSelectedPayment(fallback, detail: nil)
                return
            }
        }

        self.methodSelectionView.isHidden = true
    }

    @objc private func methodSelectionTapped(_ gesture: UITapGestureRecognizer) {
        let title = "Snabble.Shoppingcart.howToPay".localized()
        let sheet = AlertController(title: title, message: nil, preferredStyle: .actionSheet)

        // combine all payment methods of all projects
        let allAppMethods = Set(SnabbleAPI.projects.flatMap { $0.paymentMethods })
        // and get them in the desired display order
        let allMethods = RawPaymentMethod.orderedMethods.filter { allAppMethods.contains($0) }

        var actions = [PaymentMethodAction]()
        for method in allMethods {
            actions.append(contentsOf: self.actionsFor(method))
        }

        var iconMap = [AlertAction: UIImage]()

        // add an action for each method
        for actionData in actions {
            let action = AlertAction(attributedTitle: actionData.title, style: .normal) { _ in
                if actionData.selectable {
                    self.setSelectedPayment(actionData.method, detail: actionData.methodDetail)
                }
            }
            let icon = actionData.active ? actionData.icon : actionData.icon?.grayscale()
            action.imageView.image = icon
            if actionData.active {
                iconMap[action] = icon
            }

            sheet.addAction(action)
        }

        // add the "add method" action
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.label
        ]
        let addTitle = NSAttributedString(string: "Snabble.Payment.add".localized(), attributes: titleAttrs)
        let add = AlertAction(attributedTitle: addTitle, style: .normal) { _ in
            if SnabbleUI.implicitNavigation {
                let selection = PaymentMethodAddViewController(showFromCart: true, self.parentVC)
                self.parentVC?.navigationController?.pushViewController(selection, animated: true)
            } else {
                let msg = "navigationDelegate may not be nil when using explicit navigation"
                assert(self.paymentMethodNavigationDelegate != nil, msg)
                self.paymentMethodNavigationDelegate?.addMethod(fromCart: true)
            }
        }
        add.imageView.image = UIImage.fromBundle("SnabbleSDK/payment/payment-add")

        let dataRequiring = SnabbleUI.project.paymentMethods.filter { $0.dataRequired }
        let userMethods = Set(PaymentMethodDetails.read().map { $0.rawMethod })
        let requiring = Set(dataRequiring).subtracting(userMethods)

        if !requiring.isEmpty {
            sheet.addAction(add)
        }

        // add the cancel action
        let cancelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        let cancelTitle = NSAttributedString(string: "Snabble.Cancel".localized(), attributes: cancelAttrs)
        sheet.addAction(AlertAction(attributedTitle: cancelTitle, style: .preferred))

        sheet.shouldDismissHandler = { action in
            if let action = action, let icon = iconMap[action] {
                UIView.transition(with: self.methodIcon, duration: 0.16, options: .transitionCrossDissolve, animations: {
                    self.methodIcon.image = icon
                })
            }
            return true
        }

        self.parentVC?.present(sheet, animated: true)
    }

    private func actionsFor(_ method: RawPaymentMethod) -> [PaymentMethodAction] {
        let isProjectMethod = SnabbleUI.project.paymentMethods.contains(method)
        let cartMethod = self.shoppingCart.paymentMethods?.first { $0.method == method }
        let isCartMethod = cartMethod != nil
        let userMethods = PaymentMethodDetails.read().filter { $0.rawMethod == method }
        let isUserMethod = !userMethods.isEmpty

        var detailText: String?

        switch method {
        case .externalBilling, .customerCardPOS:
            if !isProjectMethod || userMethods.isEmpty {
                return []
            }

            let actions = userMethods.map { userMethod -> PaymentMethodAction in
                var color: UIColor = .label
                if case let PaymentMethodUserData.tegutEmployeeCard(data) = userMethod.methodData {
                    detailText = data.cardNumber
                }

                if !isCartMethod {
                    detailText = "Snabble.Shoppingcart.notForThisPurchase".localized()
                    color = .secondaryLabel
                }

                let title = self.title(userMethod.displayName, detailText, color)
                return PaymentMethodAction(title, method, userMethod, selectable: true, active: isCartMethod)
            }
            return actions

        case .creditCardAmericanExpress, .creditCardVisa, .creditCardMastercard, .deDirectDebit, .paydirektOneKlick:
            if !isProjectMethod {
                if isUserMethod {
                    let title = self.title(method.displayName, "Snabble.Shoppingcart.notForVendor".localized(), .secondaryLabel)
                    let action = PaymentMethodAction(title, method, nil, selectable: false, active: false)
                    return [action]
                } else {
                    return []
                }
            }

            if !isCartMethod && isUserMethod {
                let title = self.title(method.displayName, "Snabble.Shoppingcart.notForThisPurchase".localized(), .secondaryLabel)
                let action = PaymentMethodAction(title, method, nil, selectable: false, active: false)
                return [action]
            } else if !userMethods.isEmpty {
                let actions = userMethods.map { userMethod -> PaymentMethodAction in
                    let title = self.title(method.displayName, userMethod.displayName, .label)
                    return PaymentMethodAction(title, method, userMethod, selectable: true, active: true)
                }
                return actions
            } else {
                let title = self.title(method.displayName, "Snabble.Shoppingcart.noPaymentData".localized(), .label)
                let action = PaymentMethodAction(title, method, nil, selectable: true, active: false)
                return [action]
            }

        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
            if !isProjectMethod {
                return []
            }
        }

        let title = self.title(method.displayName, detailText, .label)
        let action = PaymentMethodAction(title, method, nil, selectable: true, active: true)

        return [action]
    }

    private func title(_ titleText: String, _ subtitleText: String?, _ textColor: UIColor) -> NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: textColor
        ]

        let newline = subtitleText != nil ? "\n" : ""
        let title = NSMutableAttributedString(string: "\(titleText)\(newline)", attributes: titleAttributes)

        if let subtitleText = subtitleText {
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let subTitle = NSAttributedString(string: subtitleText, attributes: subtitleAttributes)
            title.append(subTitle)
        }

        return title
    }
}
