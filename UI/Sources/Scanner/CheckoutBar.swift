//
//  CheckoutBar.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley
import SnabbleCore
import SnabbleAssetProviding

final class CheckoutBar: UIView {
    private weak var itemCountLabel: UILabel?
    private weak var totalPriceLabel: UILabel?
    private weak var paymentStackView: UIStackView?
    private weak var methodSelectionStackView: UIStackView?
    private weak var noPaymentLabel: UILabel?
    private weak var methodIcon: UIImageView?
    private weak var chevronImage: UIImageView?
    private weak var checkoutButton: UIButton?

    private var notAllMethodsAvailableShown = false
    private var checkoutNotAvailableShown = false
    private weak var limitAlert: UIAlertController?

    private var methodSelector: PaymentMethodSelector?
    private weak var parentVC: (UIViewController & AnalyticsDelegate)?
    private let shoppingCart: ShoppingCart
    weak var shoppingCartDelegate: ShoppingCartDelegate?

    init(_ parentVC: UIViewController & AnalyticsDelegate, _ shoppingCart: ShoppingCart) {
        self.parentVC = parentVC
        self.shoppingCart = shoppingCart
        super.init(frame: .zero)

        self.setupUI()

        if let methodSelectionStackView = self.methodSelectionStackView, let methodIcon = self.methodIcon {
            self.methodSelector = PaymentMethodSelector(parentVC, methodSelectionStackView, methodIcon, self.shoppingCart)
        }
        self.methodSelector?.delegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let summaryLayoutGuide = UILayoutGuide()

        let itemCountLabel = UILabel()
        itemCountLabel.translatesAutoresizingMaskIntoConstraints = false
        itemCountLabel.font = .preferredFont(forTextStyle: .footnote)
        itemCountLabel.adjustsFontForContentSizeCategory = true
        itemCountLabel.textColor = .secondaryLabel
        itemCountLabel.textAlignment = .left

        let totalPriceLabel = UILabel()
        totalPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        totalPriceLabel.font = .preferredFont(forTextStyle: .title2, weight: .bold)
        totalPriceLabel.adjustsFontForContentSizeCategory = true
        totalPriceLabel.textColor = .label
        totalPriceLabel.textAlignment = .right

        let paymentStackView = UIStackView()
        paymentStackView.translatesAutoresizingMaskIntoConstraints = false
        paymentStackView.axis = .horizontal
        paymentStackView.distribution = .fill
        paymentStackView.alignment = .fill
        paymentStackView.spacing = 16

        let methodSelectionStackView = UIStackView()
        methodSelectionStackView.translatesAutoresizingMaskIntoConstraints = false
        methodSelectionStackView.axis = .horizontal
        methodSelectionStackView.distribution = .fill
        methodSelectionStackView.spacing = 4
        methodSelectionStackView.isLayoutMarginsRelativeArrangement = true
        methodSelectionStackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        methodSelectionStackView.backgroundColor = .systemBackground
        methodSelectionStackView.layer.masksToBounds = true
        methodSelectionStackView.layer.cornerRadius = CGFloat.primaryButtonRadius()
        methodSelectionStackView.layer.borderColor = UIColor.systemGray6.cgColor
        methodSelectionStackView.layer.borderWidth = 1 / UIScreen.main.scale

        let noPaymentLabel = UILabel()
        noPaymentLabel.translatesAutoresizingMaskIntoConstraints = false
        noPaymentLabel.font = .preferredFont(forTextStyle: .body, weight: .medium)
        noPaymentLabel.adjustsFontForContentSizeCategory = true
        noPaymentLabel.textColor = .label
        noPaymentLabel.textAlignment = .center
        noPaymentLabel.text = Asset.localizedString(forKey: "Snabble.Shoppingcart.BuyProducts.selectPaymentMethod")

        let methodIcon = UIImageView()
        methodIcon.translatesAutoresizingMaskIntoConstraints = false
        methodIcon.contentMode = .scaleAspectFit
        methodIcon.image = Asset.image(named: "SnabbleSDK/payment/payment-sco")

        let chevronImage = UIImageView()
        chevronImage.translatesAutoresizingMaskIntoConstraints = false
        chevronImage.contentMode = .scaleAspectFit
        chevronImage.image = Asset.image(named: "SnabbleSDK/icon-chevron-down")

        let checkoutButton = UIButton(type: .system)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.setTitle(Asset.localizedString(forKey: "Snabble.Shoppingcart.BuyProducts.now"), for: .normal)
        let disabledColor = UIColor.onProjectPrimary().withAlphaComponent(0.5)
        checkoutButton.setTitleColor(disabledColor, for: .disabled)
        checkoutButton.titleLabel?.font = .preferredFont(forTextStyle: .body, weight: UIFont.buttonWeight())
        checkoutButton.titleLabel?.adjustsFontForContentSizeCategory = true
        checkoutButton.makeSnabbleButton()

        checkoutButton.isEnabled = true
        checkoutButton.isUserInteractionEnabled = true
        checkoutButton.addTarget(self, action: #selector(checkoutTapped(_:)), for: .touchUpInside)

        addLayoutGuide(summaryLayoutGuide)
        addSubview(paymentStackView)
        addSubview(itemCountLabel)
        addSubview(totalPriceLabel)
        paymentStackView.addArrangedSubview(methodSelectionStackView)
        paymentStackView.addArrangedSubview(checkoutButton)
        methodSelectionStackView.addArrangedSubview(noPaymentLabel)
        methodSelectionStackView.addArrangedSubview(methodIcon)
        methodSelectionStackView.addArrangedSubview(chevronImage)

        self.itemCountLabel = itemCountLabel
        self.totalPriceLabel = totalPriceLabel
        self.paymentStackView = paymentStackView
        self.methodSelectionStackView = methodSelectionStackView
        self.noPaymentLabel = noPaymentLabel
        self.methodIcon = methodIcon
        self.chevronImage = chevronImage
        self.checkoutButton = checkoutButton

        NSLayoutConstraint.activate([
            summaryLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
            summaryLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            summaryLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
            summaryLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: itemCountLabel.heightAnchor).usingPriority(.defaultHigh + 3),
            summaryLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: totalPriceLabel.heightAnchor).usingPriority(.defaultHigh + 3),

            itemCountLabel.leadingAnchor.constraint(equalTo: summaryLayoutGuide.leadingAnchor),
            itemCountLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
            itemCountLabel.topAnchor.constraint(equalTo: summaryLayoutGuide.topAnchor).usingPriority(.defaultHigh + 4),
            itemCountLabel.bottomAnchor.constraint(equalTo: summaryLayoutGuide.bottomAnchor).usingPriority(.defaultHigh + 4),

            totalPriceLabel.leadingAnchor.constraint(equalTo: itemCountLabel.trailingAnchor),
            totalPriceLabel.trailingAnchor.constraint(equalTo: summaryLayoutGuide.trailingAnchor),
            totalPriceLabel.topAnchor.constraint(equalTo: summaryLayoutGuide.topAnchor).usingPriority(.defaultHigh + 4),
            summaryLayoutGuide.bottomAnchor.constraint(equalTo: totalPriceLabel.bottomAnchor).usingPriority(.defaultHigh + 4),

            paymentStackView.topAnchor.constraint(equalToSystemSpacingBelow: summaryLayoutGuide.bottomAnchor, multiplier: 1).usingPriority(.defaultHigh + 3),
            paymentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            paymentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            paymentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            methodSelectionStackView.heightAnchor.constraint(equalToConstant: 48).usingPriority(.defaultHigh + 1),
            methodSelectionStackView.widthAnchor.constraint(equalToConstant: 80).usingPriority(.defaultHigh - 1),
            methodIcon.widthAnchor.constraint(equalToConstant: 38).usingPriority(.defaultHigh + 2),
            chevronImage.widthAnchor.constraint(equalToConstant: 16).usingPriority(.defaultHigh + 2),
            chevronImage.heightAnchor.constraint(equalToConstant: 16).usingPriority(.defaultHigh - 3),
            checkoutButton.heightAnchor.constraint(equalToConstant: 48).usingPriority(.defaultHigh),
            checkoutButton.widthAnchor.constraint(equalToConstant: 280).usingPriority(.defaultHigh - 2)
        ])
    }

    private func updateViewHierarchy(for paymentMethod: RawPaymentMethod?) {
        let paymentMethodSelected = paymentMethod != nil
        self.checkoutButton?.isHidden = !paymentMethodSelected
        self.methodIcon?.isHidden = !paymentMethodSelected
        self.noPaymentLabel?.isHidden = paymentMethodSelected
    }

    func updateTotals(updating: Bool = false) {
        let numberOfItems = shoppingCart.numberOfItems
        let formatter = PriceFormatter(SnabbleCI.project)
        let backendCartInfo = shoppingCart.backendCartInfo

        let nilPrice: Bool
        if let items = backendCartInfo?.lineItems {
            let productsNoPrice = items.filter { $0.type == .default && $0.totalPrice == nil }
            nilPrice = !productsNoPrice.isEmpty
        } else {
            nilPrice = false
        }

        let cartTotal = SnabbleCI.project.displayNetPrice ? backendCartInfo?.netPrice : backendCartInfo?.totalPrice

        let totalPrice = nilPrice ? nil : (cartTotal ?? shoppingCart.total)
        if let total = totalPrice {
            let formattedTotal = formatter.format(total)
            self.totalPriceLabel?.text = formattedTotal
            self.checkCheckoutLimits(total)
        } else {
            self.totalPriceLabel?.text = " "
        }

        self.itemCountLabel?.text = Asset.localizedString(forKey: "Snabble.Shoppingcart.numberOfItems", arguments: numberOfItems)

        if  self.checkoutButton?.titleLabel?.text == nil {
            self.checkoutButton?.setTitle(Asset.localizedString(forKey: updating || totalPrice ?? 0 > 0 ? "Snabble.Shoppingcart.BuyProducts.now" : "Snabble.Shoppingcart.completePurchase"), for: .normal)
        }
        self.checkoutButton?.isEnabled = !updating && numberOfItems > 0 && (totalPrice ?? 0) >= 0

        self.methodSelector?.updateAvailablePaymentMethods()
        updateViewHierarchy(for: self.methodSelector?.selectedPayment?.method)
    }

    func updateSelectionVisibility() {
        self.methodSelector?.updateSelectionVisibility()
    }

    private func pauseScanning() {
        let drawer = self.parentVC as? ScannerDrawerViewController
        let scanner = drawer?.pulleyViewController?.primaryContentViewController as? ScanningViewController
        scanner?.pauseScanning()
    }

    private func resumeScanning() {
        let drawer = self.parentVC as? ScannerDrawerViewController
        let scanner = drawer?.pulleyViewController?.primaryContentViewController as? ScanningViewController
        scanner?.resumeScanning()
    }

    @objc private func checkoutTapped(_ sender: Any) {
        pauseScanning()

        let project = SnabbleCI.project
        self.shoppingCartDelegate?.checkoutAllowed(project: project, cart: shoppingCart) { start in
            if start {
                if self.taxationInfoRequired() {
                    self.requestTaxationInfo()
                } else {
                    self.startCheckout()
                }
            }
        }
    }

    private func startCheckout() {
        let project = SnabbleCI.project
        guard let paymentMethod = self.methodSelector?.selectedPayment?.method else {
            let selection = PaymentMethodAddViewController(parentVC)
            parentVC?.navigationController?.pushViewController(selection, animated: true)

            return
        }

        // no detail data, and there is an editing VC? Show that instead of continuing
        if self.methodSelector?.selectedPayment?.detail == nil,
            let parentVC = self.parentVC,
            paymentMethod.isAddingAllowed(showAlertOn: parentVC),
            let editVC = paymentMethod.editViewController(with: project.id, parentVC) {
            parentVC.navigationController?.pushViewController(editVC, animated: true)
            return
        }

        let button = self.checkoutButton!

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        button.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        button.isEnabled = false

        self.shoppingCart.createCheckoutInfo(SnabbleCI.project, timeout: 10) { result in
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            button.isEnabled = true

            switch result {
            case .success(let info):
                // force any required info to be re-requested on the next attempt
                self.shoppingCart.resetInformationData() // requiredInformationData = []

                let detail = self.methodSelector?.selectedPayment?.detail
                let cart = self.shoppingCart
                self.shoppingCartDelegate?.gotoPayment(paymentMethod, detail, info, cart) { didStart in
                    if !didStart {
                        self.resumeScanning()
                    }
                }
            case .failure(let error):
                let handled = self.shoppingCartDelegate?.handleCheckoutError(error) ?? false
                if !handled {
                    if let offendingSkus = error.details?.compactMap({ $0.sku }) {
                        self.showProductError(offendingSkus)
                        return
                    }

                    if paymentMethod.offline {
                        // if the payment method works offline, ignore the error and continue anyway
                        let info = SignedCheckoutInfo([paymentMethod])
                        self.shoppingCartDelegate?.gotoPayment(paymentMethod, nil, info, self.shoppingCart) { _ in }
                        return
                    }

                    if case SnabbleError.urlError = error {
                        self.shoppingCartDelegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.offlineHint"))
                        return
                    }

                    switch error.type {
                    case .noAvailableMethod:
                        self.shoppingCartDelegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.noMethodAvailable"))
                    default:
                        self.shoppingCartDelegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.errorStarting"))
                    }
                }
            }
        }
    }

    private func showProductError(_ skus: [String]) {
        var offendingProducts = [String]()
        for sku in skus {
            if let item = self.shoppingCart.items.first(where: { $0.product.sku == sku }) {
                offendingProducts.append(item.product.name)
            }
        }

        let start = offendingProducts.count == 1 ? Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.one") : Asset.localizedString(forKey: "Snabble.SaleStop.errorMsg")
        let msg = start + "\n\n" + offendingProducts.joined(separator: "\n")
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.title"), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))
        parentVC?.present(alert, animated: true)
    }
}

// MARK: - taxation info
extension CheckoutBar {
    private func taxationInfoRequired() -> Bool {
        let cart = self.shoppingCart
        if let taxationInfoRequired = cart.requiredInformation.first(where: { $0.id == .taxation }) {
            return taxationInfoRequired.value == nil
        }

        return false
    }

    private func requestTaxationInfo() {
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.Taxation.pleaseChoose"),
                                      message: Asset.localizedString(forKey: "Snabble.Taxation.consumeWhere"),
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.Taxation.Consume.inhouse"), style: .default) { _ in
            self.setTaxation(to: .taxationInhouse)
            self.startCheckout()
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.Taxation.Consume.takeaway"), style: .default) { _ in
            self.setTaxation(to: .taxationTakeaway)
            self.startCheckout()
        })
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.cancel"), style: .cancel, handler: nil))

        self.parentVC?.present(alert, animated: true)
    }

    private func setTaxation(to taxation: RequiredInformation) {
        self.shoppingCart.setTaxation(to: taxation)
    }
}

extension CheckoutBar: PaymentMethodSelectorDelegate {
    func paymentMethodSelector(_ paymentMethodSelector: PaymentMethodSelector, didSelectMethod rawPaymentMethod: RawPaymentMethod?) {
        updateViewHierarchy(for: rawPaymentMethod)
    }
}

extension CheckoutBar {
    private func checkCheckoutLimits(_ totalPrice: Int) {
        let formatter = PriceFormatter(SnabbleCI.project)

        if let notAllMethodsAvailable = SnabbleCI.project.checkoutLimits?.notAllMethodsAvailable {
            if totalPrice > notAllMethodsAvailable {
                if !self.notAllMethodsAvailableShown {
                    let limit = formatter.format(notAllMethodsAvailable)
                    self.showLimitAlert(Asset.localizedString(forKey: "Snabble.LimitsAlert.notAllMethodsAvailable", arguments: limit))
                    self.notAllMethodsAvailableShown = true
                }
            } else {
                self.notAllMethodsAvailableShown = false
            }
        }

        if let checkoutNotAvailable = SnabbleCI.project.checkoutLimits?.checkoutNotAvailable {
            if totalPrice > checkoutNotAvailable {
                if !self.checkoutNotAvailableShown {
                    let limit = formatter.format(checkoutNotAvailable)
                    self.showLimitAlert(Asset.localizedString(forKey: "Snabble.LimitsAlert.checkoutNotAvailable", arguments: limit))
                    self.checkoutNotAvailableShown = true
                }
            } else {
                self.checkoutNotAvailableShown = false
            }
        }
    }

    private func showLimitAlert(_ msg: String) {
        guard self.limitAlert == nil else {
            return
        }

        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.LimitsAlert.title"), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
            self.limitAlert = nil
        })
        UIApplication.topViewController()?.present(alert, animated: true)
        self.limitAlert = alert
    }
}
