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
    private weak var methodSelectionView: UIView?
    private weak var methodIcon: UIImageView?

    private(set) var methodTap: UITapGestureRecognizer!

    weak var paymentMethodNavigationDelegate: PaymentMethodNavigationDelegate?

    private(set) var selectedPaymentMethod: RawPaymentMethod?
    private(set) var selectedPaymentDetail: PaymentMethodDetail?

    // set to true when the user makes an explicit selection from the action sheet,
    // this disables the automatic/default method selection
    private var userMadeExplicitSelection = false

    private var shoppingCart: ShoppingCart

    init(_ parentVC: (UIViewController & AnalyticsDelegate)?,
         _ selectionView: UIView,
         _ methodIcon: UIImageView,
         _ cart: ShoppingCart
    ) {
        self.parentVC = parentVC
        self.methodSelectionView = selectionView
        self.methodIcon = methodIcon
        self.shoppingCart = cart

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.methodSelectionTapped(_:)))
        self.methodTap = tap
        self.methodSelectionView?.addGestureRecognizer(tap)

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
        self.methodSelectionView?.isHidden = hidden

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
        self.methodTap.isEnabled = false
    }

    func updateAvailablePaymentMethods() {
        self.methodTap.isEnabled = true

        let paymentMethods = self.shoppingCart.paymentMethods?.filter { $0.method.isAvailable } ?? []
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
        self.methodIcon?.image = icon
        if method?.dataRequired == true && detail == nil {
            self.methodIcon?.image = icon?.grayscale()
        }
        self.methodTap.isEnabled = true
    }

    private func selectedMethodIsValid() -> Bool {
        guard let method = self.selectedPaymentMethod else {
            return false
        }

        if method.dataRequired {
            return self.selectedPaymentDetail != nil
        }
        return true
    }

    private func setDefaultPaymentMethod() {
        if self.userMadeExplicitSelection && selectedMethodIsValid() {
            return
        } else {
            self.userMadeExplicitSelection = false
        }

        let userMethods = PaymentMethodDetails.read().filter { $0.rawMethod.isAvailable }

        let projectMethods = SnabbleUI.project.paymentMethods.filter { $0.isAvailable }
        let cartMethods = self.shoppingCart.paymentMethods?.map { $0.method }.filter { $0.isAvailable } ?? []
        var availableMethods = cartMethods.isEmpty ? projectMethods : cartMethods

        // use Apple Pay, if possible
        if availableMethods.contains(.applePay) && ApplePaySupport.canMakePayments() {
            self.setSelectedPayment(.applePay, detail: nil)
            return
        } else if !ApplePaySupport.applePaySupported() {
            availableMethods.removeAll { $0 == .applePay }
        }

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

        self.methodSelectionView?.isHidden = true
    }

    private func userSelectedPaymentMethod(with actionData: PaymentMethodAction) {
        guard actionData.selectable else {
            return
        }

        self.userMadeExplicitSelection = true
        let method = actionData.method
        let detail = actionData.methodDetail
        self.setSelectedPayment(method, detail: detail)

        // if the selected method is missing its detail data, immediately open the edit VC for the method
        guard
            detail == nil,
            let parent = self.parentVC,
            method.isAddingAllowed(showAlertOn: parent) == true,
            let editVC = method.editViewController(with: SnabbleUI.project.id, parent)
        else {
            return
        }

        if SnabbleUI.implicitNavigation {
            self.parentVC?.navigationController?.pushViewController(editVC, animated: true)
        } else {
            self.paymentMethodNavigationDelegate?.addData(for: method, in: SnabbleUI.project.id)
        }
    }

    @objc private func methodSelectionTapped(_ gesture: UITapGestureRecognizer) {
        let title = L10n.Snabble.Shoppingcart.howToPay
        let sheet = AlertController(title: title, message: nil, preferredStyle: .actionSheet)
        sheet.visualStyle = .snabbleActionSheet

        // combine all payment methods of all projects
        let allAppMethods = Set(SnabbleAPI.projects.flatMap { $0.paymentMethods }.filter { $0.isAvailable })
        // and get them in the desired display order
        let allMethods = RawPaymentMethod.orderedMethods.filter { allAppMethods.contains($0) }

        var actions = [PaymentMethodAction]()
        for method in allMethods {
            actions.append(contentsOf: self.actionsFor(method))
        }

        var iconMap = [AlertAction: UIImage]()

        let isAnyActive = actions.contains { $0.active == true }

        // add an action for each method
        for actionData in actions {
            let action = AlertAction(attributedTitle: actionData.title, style: .normal) { _ in
                self.userSelectedPaymentMethod(with: actionData)
            }
            let icon = isAnyActive && !actionData.active ? actionData.icon?.grayscale() : actionData.icon
            action.imageView.image = icon

            if actionData.active {
                iconMap[action] = icon
            }

            sheet.addAction(action)
        }

        // add the cancel action
        sheet.addAction(AlertAction(title: L10n.Snabble.cancel, style: .preferred))

        sheet.shouldDismissHandler = { action in
            if let action = action, let icon = iconMap[action], let methodIcon = self.methodIcon {
                UIView.transition(with: methodIcon, duration: 0.16, options: .transitionCrossDissolve, animations: {
                    methodIcon.image = icon
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
                    detailText = L10n.Snabble.Shoppingcart.notForThisPurchase
                    color = .secondaryLabel
                }

                let title = self.title(userMethod.displayName, detailText, color)
                return PaymentMethodAction(title, method, userMethod, selectable: true, active: isCartMethod)
            }
            return actions

        case .creditCardAmericanExpress, .creditCardVisa, .creditCardMastercard, .deDirectDebit, .paydirektOneKlick,
             .twint, .postFinanceCard:
            if !isProjectMethod {
                if isUserMethod {
                    let title = self.title(method.displayName, L10n.Snabble.Shoppingcart.notForVendor, .secondaryLabel)
                    let action = PaymentMethodAction(title, method, nil, selectable: false, active: false)
                    return [action]
                } else {
                    return []
                }
            }

            if !isCartMethod && isUserMethod {
                let title = self.title(method.displayName, L10n.Snabble.Shoppingcart.notForThisPurchase, .secondaryLabel)
                let action = PaymentMethodAction(title, method, nil, selectable: false, active: false)
                return [action]
            } else if !userMethods.isEmpty {
                let actions = userMethods.map { userMethod -> PaymentMethodAction in
                    let title = self.title(method.displayName, userMethod.displayName, .label)
                    return PaymentMethodAction(title, method, userMethod, selectable: true, active: true)
                }
                return actions
            } else {
                let subtitle = L10n.Snabble.Shoppingcart.noPaymentData
                let title = self.title(method.displayName, subtitle, .label)
                let action = PaymentMethodAction(title, method, nil, selectable: true, active: false)
                return [action]
            }

        case .applePay:
            if !ApplePaySupport.applePaySupported() || !isCartMethod {
                return []
            }

            let canMakePayments = ApplePaySupport.canMakePayments()
            let subtitle = canMakePayments ? nil : L10n.Snabble.Shoppingcart.notForThisPurchase
            let title = self.title(method.displayName, subtitle, .label)
            let action = PaymentMethodAction(title, method, nil, selectable: canMakePayments, active: false)
            return [action]

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
