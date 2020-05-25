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
    let active: Bool

    init(_ title: NSAttributedString, _ method: RawPaymentMethod, _ methodDetail: PaymentMethodDetail?, _ active: Bool) {
        self.title = title
        self.method = method
        self.methodDetail = methodDetail
        self.icon = methodDetail?.icon ?? method.icon
        self.active = active
    }
}

final class PaymentMethodSelector {
    private var parentVC: UIViewController & AnalyticsDelegate
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

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdating(_:)), name: .snabbleCartUpdating, object: nil)

        if #available(iOS 13.0, *) {
            self.methodSpinner.style = .medium
        }

        self.setDefaultPaymentMethod()
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

        self.methodSelectionView.isHidden = paymentMethods.count < 2
    }

    private func setSelectedPayment(_ method: RawPaymentMethod?, detail: PaymentMethodDetail?) {
        self.selectedPaymentMethod = method
        self.selectedPaymentDetail = detail

        self.methodIcon.image = detail?.icon ?? method?.icon
        self.methodTap?.isEnabled = true
        self.methodSpinner.stopAnimating()
    }

    private func setDefaultPaymentMethod() {
        let count = self.shoppingCart.paymentMethods?.count ?? 0
        self.methodSelectionView.isHidden = count < 2

        let userMethods = PaymentMethodDetails.read()

        for method in RawPaymentMethod.allCases {
            let ok = self.shoppingCart.paymentMethods?.contains { $0.method == method }
            if ok == true, let userMethod = userMethods.first(where: { $0.rawMethod == method }) {
                self.setSelectedPayment(method, detail: userMethod)
                return
            }
        }

        let methods: [RawPaymentMethod] = [ .gatekeeperTerminal, .qrCodeOffline, .qrCodePOS, .customerCardPOS ]

        for method in methods {
            if self.shoppingCart.paymentMethods?.first(where: { $0.method == method }) != nil {
                self.setSelectedPayment(method, detail: nil)
                return
            }
        }

        self.methodIcon.image = nil
        self.methodSpinner.startAnimating()
    }

    @objc private func methodSelectionTapped(_ gesture: UITapGestureRecognizer) {
        let title = "Snabble.Shoppingcart.howToPay".localized()
        let sheet = AlertController(title: title, message: nil, preferredStyle: .actionSheet)

        let allProjectMethods = Set(SnabbleAPI.projects.flatMap { $0.paymentMethods })
        let allMethods = RawPaymentMethod.orderedMethods.filter { allProjectMethods.contains($0) }
        var actions = [PaymentMethodAction]()
        for method in allMethods {
            actions.append(contentsOf: self.actionsFor(method))
        }

        var iconMap = [AlertAction: UIImage]()

        // add an action for each method
        for actionData in actions {
            let action = AlertAction(attributedTitle: actionData.title, style: .normal) { _ in
                if actionData.active {
                    self.setSelectedPayment(actionData.method, detail: actionData.methodDetail)
                }
            }
            let icon = actionData.active ? actionData.icon : actionData.icon?.grayscale()
            action.imageView.image = icon
            if actionData.active {
                iconMap[action] = actionData.icon
            }

            sheet.addAction(action)
        }

        // add the "add method" action
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: self.textColor
        ]
        let addTitle = NSAttributedString(string: "Snabble.Payment.add".localized(), attributes: titleAttrs)
        let add = AlertAction(attributedTitle: addTitle, style: .normal) { _ in
            let methods = MethodProjects.initialize()
            let selection = MethodSelectionViewController(methods, self.parentVC)
            if SnabbleUI.implicitNavigation {
                self.parentVC.navigationController?.pushViewController(selection, animated: true)
            } else {
                let msg = "navigationDelegate may not be nil when using explicit navigation"
                assert(self.paymentMethodNavigationDelegate != nil, msg)
                self.paymentMethodNavigationDelegate?.addMethod()
            }
        }
        add.imageView.image = UIImage.fromBundle("SnabbleSDK/payment/payment-add")

        let dataRequiring = self.shoppingCart.paymentMethods?.filter { $0.method.dataRequired }.map { $0.method } ?? []
        let userMethods = Set(PaymentMethodDetails.read().map { $0.rawMethod })
        let requiring = Set(dataRequiring).subtracting(userMethods)

        if !requiring.isEmpty {
            sheet.addAction(add)
        }

        // add the cancel action
        let cancelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: self.textColor
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

        self.parentVC.present(sheet, animated: true)
    }

    private func actionsFor(_ method: RawPaymentMethod) -> [PaymentMethodAction] {
        let isProjectMethod = SnabbleUI.project.paymentMethods.contains(method)
        let cartMethod = self.shoppingCart.paymentMethods?.first { $0.method == method }
        let userMethods = PaymentMethodDetails.read().filter { $0.rawMethod == method }
        let isUserMethod = userMethods.contains { $0.rawMethod == method }

        var detailText: String?

        switch method {
        case .externalBilling, .customerCardPOS:
            if !isProjectMethod {
                return []
            }

            if userMethods.isEmpty {
                return []
            }

            let actions = userMethods.map { userMethod -> PaymentMethodAction in
                if case let PaymentMethodUserData.tegutEmployeeCard(data) = userMethod.methodData {
                    detailText = data.cardNumber
                }

                let title = self.title(userMethod.displayName, detailText, self.textColor)
                return PaymentMethodAction(title, method, userMethod, true)
            }
            return actions

        case .creditCardAmericanExpress, .creditCardVisa, .creditCardMastercard, .deDirectDebit, .paydirektOneKlick:
            if !isProjectMethod {
                if isUserMethod {
                    let title = self.title(method.displayName, "Snabble.Shoppingcart.notForVendor".localized(), self.subTitleColor)
                    let action = PaymentMethodAction(title, method, nil, false)
                    return [action]
                } else {
                    return []
                }
            }

            if cartMethod == nil {
                let title = self.title(method.displayName, "Snabble.Shoppingcart.notFotThisPurchase".localized(), self.subTitleColor)
                let action = PaymentMethodAction(title, method, nil, false)
                return [action]
            } else if !userMethods.isEmpty {
                let actions = userMethods.map { userMethod -> PaymentMethodAction in
                    let title = self.title(method.displayName, userMethod.displayName, self.textColor)
                    return PaymentMethodAction(title, method, userMethod, true)
                }
                return actions
            } else {
                return []
            }

        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
            if !isProjectMethod {
                return []
            }
        }

        let title = self.title(method.displayName, detailText, self.textColor)
        let action = PaymentMethodAction(title, method, nil, true)

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
                .foregroundColor: self.subTitleColor
            ]
            let subTitle = NSAttributedString(string: subtitleText, attributes: subtitleAttributes)
            title.append(subTitle)
        }

        return title
    }

    private var textColor: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }

    private var subTitleColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondaryLabel
        } else {
            return .lightGray
        }
    }
}
