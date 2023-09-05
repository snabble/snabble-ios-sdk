//
//  ShoppingCart+PaymentSelection.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SDCAlertView
import SnabbleCore

private struct PaymentMethodAction {
    let title: NSAttributedString
    let icon: UIImage?
    let method: RawPaymentMethod
    let methodDetail: PaymentMethodDetail?
    let selectable: Bool
    let active: Bool

    init(title: NSAttributedString, paymentMethod: RawPaymentMethod, paymentMethodDetail: PaymentMethodDetail?, selectable: Bool, active: Bool) {
        self.title = title
        self.method = paymentMethod
        self.methodDetail = paymentMethodDetail
        self.icon = methodDetail?.icon ?? method.icon
        self.selectable = selectable
        self.active = active
    }
}

protocol PaymentMethodSelectorDelegate: AnyObject {
    func paymentMethodSelector(_ paymentMethodSelector: PaymentMethodSelector, didSelectMethod: RawPaymentMethod?)
}

final class PaymentMethodSelector {
    private weak var parentVC: (UIViewController & AnalyticsDelegate)?
    private weak var methodSelectionView: UIView?
    private weak var methodIcon: UIImageView?

    private(set) var methodTap: UITapGestureRecognizer!

    private(set) var selectedPayment: PaymentSelection?

    private var shoppingCart: ShoppingCart
    weak var delegate: PaymentMethodSelectorDelegate?

    private var payment: Payment {
        SnabbleCI.project.payment
    }
    
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
        // get details for all payment methods that could be used here
        let details = PaymentMethodDetails.read().filter { detail in
            payment.availableMethods.contains { $0 == detail.rawMethod }
        }

        // hide selection if
        // - the project only has one method,
        // - we have no payment method data for it,
        // - and none is needed for this method
        let hidden =
        payment.availableMethods.count < 2 &&
            details.isEmpty &&
        payment.availableMethods.first?.dataRequired == false

        self.methodSelectionView?.isHidden = hidden

        if let selectedMethod = selectedPayment?.method {
            if selectedMethod.dataRequired {
                if let selectedDetail = selectedPayment?.detail {
                    let method = details.first { $0 == selectedDetail }
                    if method != nil {
                        assert(method?.rawMethod == selectedMethod)
                        return
                    }
                }
            } else {
                return
            }
        }

        // no method selected, or method no longer valid: select a new default
        self.setDefaultPaymentMethod()
    }

    private func selectMethodIfValid(_ detail: PaymentMethodDetail? = nil) {
        if let detail = detail {
            // method was added, check if we can use it
            let inCart = self.shoppingCart.paymentMethods?.contains { $0.method == detail.rawMethod }
            if inCart == true {
                self.setSelectedPayment(detail.rawMethod, detail: detail)
            } else if self.payment.userDetails.contains(detail), detail != self.selectedPayment?.detail {
                self.setSelectedPayment(detail.rawMethod, detail: detail)
            }
        } else {
            // method was deleted, check if it was the selected one
            if let selectedDetail = self.selectedPayment?.detail {
                self.selectedPayment = nil
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

        if !payment.availableMethods.contains(where: { $0 == selectedPayment?.method }) {
            self.setDefaultPaymentMethod()
        } else {
            self.setSelectedPayment(self.selectedPayment?.method, detail: self.selectedPayment?.detail)
        }
    }

    private func setSelectedPayment(_ method: RawPaymentMethod?, detail: PaymentMethodDetail?) {
        self.selectedPayment = PaymentSelection.paymentSelection(method, detail: detail)
        
        let icon = detail?.icon ?? method?.icon
        self.methodIcon?.image = icon
        if method?.dataRequired == true && detail == nil {
            self.methodIcon?.image = icon?.grayscale()
        }
        self.methodTap.isEnabled = true
        delegate?.paymentMethodSelector(self, didSelectMethod: method)
    }

    private func setDefaultPaymentMethod() {
        self.selectedPayment = payment.preferredPayment
    }

    private func userSelectedPaymentMethod(with actionData: PaymentMethodAction) {
        guard actionData.selectable else {
            return
        }
        let method = actionData.method
        let detail = actionData.methodDetail

        // if the selected method is missing its detail data, immediately open the edit VC for the method
        if
            detail == nil,
            let parent = parentVC,
            method.isAddingAllowed(showAlertOn: parent) == true,
            let editVC = method.editViewController(with: SnabbleCI.project.id, parent)
        {
            parent.navigationController?.pushViewController(editVC, animated: true)
        } else if method == .applePay && !ApplePay.canMakePayments(with: SnabbleCI.project.id) {
            ApplePay.openPaymentSetup()
        } else {
            setSelectedPayment(method, detail: detail)
        }
    }

    @objc private func methodSelectionTapped(_ gesture: UITapGestureRecognizer) {
        let title = Asset.localizedString(forKey: "Snabble.Shoppingcart.howToPay")
        let sheet = AlertController(title: title, message: nil, preferredStyle: .actionSheet)
        sheet.visualStyle = .snabbleActionSheet

        // combine all payment methods of all projects
        let allAppMethods = Set(
            Snabble.shared.projects
                .flatMap { $0.paymentMethods }
                .filter { $0.isAvailable }
        )

        // and get them in the desired display order
        let availableOrderedMethods = RawPaymentMethod.orderedMethods
            .filter { allAppMethods.contains($0) }
            .filter { payment.availableMethods.contains($0) }

        var actions = [PaymentMethodAction]()
        for method in availableOrderedMethods {
            actions.append(
                contentsOf: actionsFor(
                    method,
                    withPaymentMethodDetails: payment.userDetails,
                    andSupportedMethods: shoppingCart.paymentMethods?.map { $0.method }
                )
            )
        }

        var iconMap = [AlertAction: UIImage]()

        let isAnyActive = actions.contains { $0.active == true && $0.method.offline == false }

        // add an action for each method
        for action in actions {
            let alertAction = AlertAction(attributedTitle: action.title, style: .normal) { [self] _ in
                if action.selectable {
                    userSelectedPaymentMethod(with: action)
                }
            }

            let icon = isAnyActive && !(action.active || action.methodDetail != nil) ? action.icon?.grayscale() : action.icon
            alertAction.imageView.image = icon
            alertAction.imageView.setContentCompressionResistancePriority(.required, for: .vertical)

            if action.active {
                iconMap[alertAction] = icon
            }

            sheet.addAction(alertAction)
        }

        // add the cancel action
        sheet.addAction(AlertAction(title: Asset.localizedString(forKey: "Snabble.cancel"), style: .preferred))

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

    private func actionsFor(
        _ method: RawPaymentMethod,
        withPaymentMethodDetails paymentMethodDetails: [PaymentMethodDetail],
        andSupportedMethods supportedMethods: [RawPaymentMethod]?
    ) -> [PaymentMethodAction] {

        let hasCartMethods = supportedMethods != nil
        let isCartMethod = supportedMethods?.contains { $0 == method } ?? false

        let paymentMethodDetails = paymentMethodDetails.filter { $0.rawMethod == method }
        let isPaymentMethodDetailAvailable = !paymentMethodDetails.isEmpty

        switch method {
        case .externalBilling, .customerCardPOS:
            if isPaymentMethodDetailAvailable {
                let actions = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodAction in
                    var color: UIColor = .label
                    var detailText: String?
                    if case let PaymentMethodUserData.tegutEmployeeCard(data) = paymentMethodDetail.methodData {
                        detailText = data.cardNumber
                    } else if case let PaymentMethodUserData.invoiceByLogin(data) = paymentMethodDetail.methodData {
                        detailText = LoginStrings.username.localizedString("Snabble.Payment.ExternalBilling") + ": " + data.username
                    }
                    
                    if hasCartMethods && !isCartMethod {
                        detailText = Asset.localizedString(forKey: "Snabble.Shoppingcart.notForThisPurchase")
                        color = .secondaryLabel
                    }
                    
                    let title = Self.attributedString(
                        forText: paymentMethodDetail.displayName,
                        withSubtitle: detailText,
                        inColor: color
                    )
                    return PaymentMethodAction(
                        title: title,
                        paymentMethod: method,
                        paymentMethodDetail: paymentMethodDetail,
                        selectable: true,
                        active: hasCartMethods ? isCartMethod : false
                    )
                }
                return actions
            } else {
                // Workaround: Bug Fix #APPS-995
                // https://snabble.atlassian.net/browse/APPS-995
                if method == .externalBilling && Snabble.shared.config.showExternalBilling == false {
                    return []
                }
                let subtitle = Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData")
                let title = Self.attributedString(
                    forText: method.displayName,
                    withSubtitle: subtitle,
                    inColor: .label)
                let action = PaymentMethodAction(
                    title: title,
                    paymentMethod: method,
                    paymentMethodDetail: nil,
                    selectable: true,
                    active: false
                )
                return [action]
            }
            
        case .creditCardAmericanExpress, .creditCardVisa, .creditCardMastercard, .deDirectDebit, .paydirektOneKlick, .twint, .postFinanceCard:
            if isPaymentMethodDetailAvailable {
                if hasCartMethods {
                    if isCartMethod {
                        let actions = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodAction in
                            let title = Self.attributedString(
                                forText: method.displayName,
                                withSubtitle: paymentMethodDetail.displayName,
                                inColor: .label
                            )
                            return PaymentMethodAction(
                                title: title,
                                paymentMethod: method,
                                paymentMethodDetail: paymentMethodDetail,
                                selectable: true,
                                active: true
                            )
                        }
                        return actions
                    } else {
                        let title = Self.attributedString(
                            forText: method.displayName,
                            withSubtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.notForThisPurchase"),
                            inColor: .secondaryLabel
                        )
                        let action = PaymentMethodAction(
                            title: title,
                            paymentMethod: method,
                            paymentMethodDetail: nil,
                            selectable: false,
                            active: false
                        )
                        return [action]
                    }
                } else {
                    let actions = paymentMethodDetails.map { paymentMethodDetail -> PaymentMethodAction in
                        let title = Self.attributedString(
                            forText: method.displayName,
                            withSubtitle: paymentMethodDetail.displayName,
                            inColor: .label
                        )
                        return PaymentMethodAction(
                            title: title,
                            paymentMethod: method,
                            paymentMethodDetail: paymentMethodDetail,
                            selectable: true,
                            active: true
                        )
                    }
                    return actions
                }
            } else {
                let subtitle = Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData")
                let title = Self.attributedString(
                    forText: method.displayName,
                    withSubtitle: subtitle,
                    inColor: .label)
                let action = PaymentMethodAction(
                    title: title,
                    paymentMethod: method,
                    paymentMethodDetail: nil,
                    selectable: true,
                    active: false
                )
                return [action]
            }
        case .applePay:
            if !hasCartMethods || isCartMethod {
                let canMakePayments = ApplePay.canMakePayments(with: SnabbleCI.project.id)
                let subtitle = canMakePayments ? nil : Asset.localizedString(forKey: "Snabble.Shoppingcart.noPaymentData")
                let title = Self.attributedString(
                    forText: method.displayName,
                    withSubtitle: subtitle,
                    inColor: .label
                )
                let action = PaymentMethodAction(
                    title: title,
                    paymentMethod: method,
                    paymentMethodDetail: nil,
                    selectable: true,
                    active: false
                )
                return [action]
            } else {
                let title = Self.attributedString(
                    forText: method.displayName,
                    withSubtitle: Asset.localizedString(forKey: "Snabble.Shoppingcart.notForVendor"),
                    inColor: .secondaryLabel
                )
                let action = PaymentMethodAction(
                    title: title,
                    paymentMethod: method,
                    paymentMethodDetail: nil,
                    selectable: false,
                    active: false
                )
                return [action]
            }
        case .qrCodePOS, .qrCodeOffline, .gatekeeperTerminal:
            break
        }

        let title = Self.attributedString(forText: method.displayName, inColor: .label)
        let action = PaymentMethodAction(
            title: title,
            paymentMethod: method,
            paymentMethodDetail: nil,
            selectable: true,
            active: true
        )

        return [action]
    }

    private static func attributedString(forText text: String, withSubtitle subtitle: String? = nil, inColor textColor: UIColor) -> NSAttributedString {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: textColor
        ]

        let newline = subtitle != nil ? "\n" : ""
        let title = NSMutableAttributedString(string: "\(text)\(newline)", attributes: titleAttributes)

        if let subtitle = subtitle {
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let subTitle = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
            title.append(subTitle)
        }

        return title
    }
}
