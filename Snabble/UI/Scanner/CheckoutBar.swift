//
//  CheckoutBar.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

final class CheckoutBar: NibView {
    @IBOutlet private var contentStack: UIStackView!
    @IBOutlet private var itemCountLabel: UILabel!
    @IBOutlet private var totalPriceLabel: UILabel!

    @IBOutlet private var paymentStackView: UIStackView!
    @IBOutlet private var methodSelectionView: UIView!
    @IBOutlet private var methodIcon: UIImageView!
    @IBOutlet private var methodSpinner: UIActivityIndicatorView!
    @IBOutlet private var checkoutButton: UIButton!

    private var methodSelector: PaymentMethodSelector?
    private weak var parentVC: (UIViewController & AnalyticsDelegate)?
    private let shoppingCart: ShoppingCart
    private weak var cartDelegate: ShoppingCartDelegate?
    weak var paymentMethodNavigationDelegate: PaymentMethodNavigationDelegate? {
        didSet {
            self.methodSelector?.paymentMethodNavigationDelegate = self.paymentMethodNavigationDelegate
        }
    }

    init(_ parentVC: UIViewController & AnalyticsDelegate, _ shoppingCart: ShoppingCart, cartDelegate: ShoppingCartDelegate?) {
        self.parentVC = parentVC
        self.shoppingCart = shoppingCart
        self.cartDelegate = cartDelegate

        super.init(frame: .zero)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.checkoutButton.addTarget(self, action: #selector(checkoutTapped(_:)), for: .touchUpInside)
        self.checkoutButton.setTitle(L10n.Snabble.Shoppingcart.BuyProducts.now, for: .normal)
        self.checkoutButton.makeSnabbleButton()

        let disabledColor = SnabbleUI.appearance.accentColor.contrast.withAlphaComponent(0.5)
        self.checkoutButton.setTitleColor(disabledColor, for: .disabled)

        self.methodSelectionView.layer.masksToBounds = true
        self.methodSelectionView.layer.cornerRadius = 8
        self.methodSelectionView.layer.borderColor = UIColor.lightGray.cgColor
        self.methodSelectionView.layer.borderWidth = 1 / UIScreen.main.scale

        self.totalPriceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)

        self.methodSelector = PaymentMethodSelector(parentVC, self.methodSelectionView, self.methodIcon, self.shoppingCart)
        self.methodSelector?.paymentMethodNavigationDelegate = self.paymentMethodNavigationDelegate
    }

    func updateTotals() {
        let numProducts = shoppingCart.numberOfProducts
        let formatter = PriceFormatter(SnabbleUI.project)
        let backendCartInfo = shoppingCart.backendCartInfo

        let nilPrice: Bool
        if let items = backendCartInfo?.lineItems {
            let productsNoPrice = items.filter { $0.type == .default && $0.totalPrice == nil }
            nilPrice = !productsNoPrice.isEmpty
        } else {
            nilPrice = false
        }

        let cartTotal = SnabbleUI.project.displayNetPrice ? backendCartInfo?.netPrice : backendCartInfo?.totalPrice

        let totalPrice = nilPrice ? nil : (cartTotal ?? shoppingCart.total)
        if let total = totalPrice {
            let formattedTotal = formatter.format(total)
            self.totalPriceLabel?.text = formattedTotal
        } else {
            self.totalPriceLabel?.text = ""
        }

        let fun = numProducts == 1 ? L10n.Snabble.Shoppingcart.NumberOfItems.one : L10n.Snabble.Shoppingcart.numberOfItems
        self.itemCountLabel?.text = fun(numProducts)

        self.methodSelector?.updateAvailablePaymentMethods()

        let shouldDisplayControls = numProducts > 0 && (totalPrice ?? 0) >= 0

        self.checkoutButton?.isEnabled = shouldDisplayControls
        self.paymentStackView.isHidden = !shouldDisplayControls
    }

    func updateSelectionVisibility() {
        self.methodSelector?.updateSelectionVisibility()
    }

    func barDidAppear() {
        // avoid auto-layout warning
        self.contentStack.spacing = 12
    }

    @objc private func checkoutTapped(_ sender: Any) {
        if taxationInfoRequired() {
            self.requestTaxationInfo()
        } else {
            startCheckout()
        }
    }

    private func startCheckout() {
        let project = SnabbleUI.project
        guard
            self.cartDelegate?.checkoutAllowed(project) == true,
            let paymentMethod = self.methodSelector?.selectedPaymentMethod
        else {
            // no payment method selected -> show the "add method" view
            if SnabbleUI.implicitNavigation {
                let selection = PaymentMethodAddViewController(parentVC)
                parentVC?.navigationController?.pushViewController(selection, animated: true)
            } else {
                let msg = "navigationDelegate may not be nil when using explicit navigation"
                assert(self.paymentMethodNavigationDelegate != nil, msg)
                self.paymentMethodNavigationDelegate?.addMethod()
            }

            return
        }

        // no detail data, and there is an editing VC? Show that instead of continuing
        if self.methodSelector?.selectedPaymentDetail == nil,
           let parentVC = self.parentVC,
           paymentMethod.isAddingAllowed(showAlertOn: parentVC),
           let editVC = paymentMethod.editViewController(with: project.id, parentVC) {
            if SnabbleUI.implicitNavigation {
                parentVC.navigationController?.pushViewController(editVC, animated: true)
            } else {
                let msg = "navigationDelegate may not be nil when using explicit navigation"
                assert(self.paymentMethodNavigationDelegate != nil, msg)
                self.paymentMethodNavigationDelegate?.addData(for: paymentMethod, in: project.id)
            }
            return
        }

        let button = self.checkoutButton!

        let spinner = UIActivityIndicatorView(style: .white)
        if #available(iOS 13.0, *) {
            spinner.style = .medium
        }
        spinner.startAnimating()
        button.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        button.isEnabled = false

        let offlineMethods = SnabbleUI.project.paymentMethods.filter { $0.offline }
        let timeout: TimeInterval = offlineMethods.contains(paymentMethod) ? 3 : 10
        self.shoppingCart.createCheckoutInfo(SnabbleUI.project, timeout: timeout) { result in
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            button.isEnabled = true

            switch result {
            case .success(let info):
                // force any required info to be re-requested on the next attempt
                self.shoppingCart.requiredInformationData = []
                self.cartDelegate?.gotoPayment(paymentMethod, self.methodSelector?.selectedPaymentDetail, info, self.shoppingCart)
            case .failure(let error):
                let handled = self.cartDelegate?.handleCheckoutError(error) ?? false
                if !handled {
                    if let offendingSkus = error.error.details?.compactMap({ $0.sku }) {
                        self.showProductError(offendingSkus)
                        return
                    }

                    switch error.error.type {
                    case .noAvailableMethod:
                        self.cartDelegate?.showWarningMessage(L10n.Snabble.Payment.noMethodAvailable)
                    case .invalidDepositVoucher:
                        self.cartDelegate?.showWarningMessage(L10n.Snabble.InvalidDepositVoucher.errorMsg)
                    default:
                        if !offlineMethods.isEmpty {
                            let info = SignedCheckoutInfo(offlineMethods)
                            self.cartDelegate?.gotoPayment(paymentMethod, self.methodSelector?.selectedPaymentDetail, info, self.shoppingCart)
                        } else {
                            self.cartDelegate?.showWarningMessage(L10n.Snabble.Payment.errorStarting)
                        }
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

        let start = offendingProducts.count == 1 ? L10n.Snabble.SaleStop.ErrorMsg.one : L10n.Snabble.SaleStop.errorMsg
        let msg = start + "\n\n" + offendingProducts.joined(separator: "\n")
        let alert = UIAlertController(title: L10n.Snabble.SaleStop.ErrorMsg.title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default, handler: nil))
        parentVC?.present(alert, animated: true)
    }

    func setCustomAppearance(_ appearance: CustomAppearance) {
        self.checkoutButton?.setCustomAppearance(appearance)
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
        let alert = UIAlertController(title: L10n.Snabble.Taxation.pleaseChoose,
                                      message: L10n.Snabble.Taxation.consumeWhere,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: L10n.Snabble.Taxation.Consume.inhouse, style: .default) { _ in
            self.shoppingCart.requiredInformationData.removeAll { $0.id == .taxation }
            self.shoppingCart.requiredInformationData.append(.taxationInhouse)
            self.startCheckout()
        })
        alert.addAction(UIAlertAction(title: L10n.Snabble.Taxation.Consume.takeaway, style: .default) { _ in
            self.shoppingCart.requiredInformationData.removeAll { $0.id == .taxation }
            self.shoppingCart.requiredInformationData.append(.taxationTakeaway)
            self.startCheckout()
        })
        alert.addAction(UIAlertAction(title: L10n.Snabble.cancel, style: .cancel, handler: nil))

        self.parentVC?.present(alert, animated: true)
    }
}
