//
//  CheckoutBar.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit

final class CheckoutBar: NibView {
    @IBOutlet private var itemCountLabel: UILabel!
    @IBOutlet private var totalPriceLabel: UILabel!

    @IBOutlet private var methodSelectionView: UIView!
    @IBOutlet private var methodIcon: UIImageView!
    @IBOutlet private var methodSpinner: UIActivityIndicatorView!
    @IBOutlet private var checkoutButton: UIButton!

    private var methodSelector: PaymentMethodSelector?
    private weak var parentVC: (UIViewController & AnalyticsDelegate)?
    private let shoppingCart: ShoppingCart
    private weak var cartDelegate: ShoppingCartDelegate?
    weak var paymentMethodNavigationDelegate: PaymentMethodNavigationDelegate?

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
        self.checkoutButton.setTitle("Snabble.Shoppingcart.buyProducts.now".localized(), for: .normal)
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

        let fmt = numProducts == 1 ? "Snabble.Shoppingcart.numberOfItems.one" : "Snabble.Shoppingcart.numberOfItems"
        self.itemCountLabel?.text = String(format: fmt.localized(), numProducts)

        self.methodSelector?.updateAvailablePaymentMethods()

        let shouldDisplayControls = numProducts > 0 && (totalPrice ?? 0) >= 0

        self.checkoutButton?.isEnabled = shouldDisplayControls
        self.checkoutButton?.isHidden = !shouldDisplayControls
        self.methodSelectionView.isHidden = !shouldDisplayControls
    }

    func updateSelectionVisibility() {
        self.methodSelector?.updateSelectionVisibility()
    }

    @objc private func checkoutTapped(_ sender: Any) {
        self.startCheckout()
    }

    private func startCheckout() {
        let project = SnabbleUI.project
        guard
            self.cartDelegate?.checkoutAllowed(project) == true,
            let paymentMethod = self.methodSelector?.selectedPaymentMethod
        else {
            // no payment method selected -> show the "add method" view
            if SnabbleUI.implicitNavigation {
                let selection = PaymentMethodAddViewController(showFromCart: true, parentVC)
                parentVC?.navigationController?.pushViewController(selection, animated: true)
            } else {
                let msg = "navigationDelegate may not be nil when using explicit navigation"
                assert(self.paymentMethodNavigationDelegate != nil, msg)
                self.paymentMethodNavigationDelegate?.addMethod(fromCart: true)
            }

            return
        }

        // no detail data, and there is an editing VC? Show that instead of continuing
        if self.methodSelector?.selectedPaymentDetail == nil,
           let parentVC = self.parentVC,
           paymentMethod.isAddingAllowed(showAlertOn: parentVC),
           let editVC = paymentMethod.editViewController(with: project.id, showFromCart: true, parentVC) {
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
                        self.cartDelegate?.showWarningMessage("Snabble.Payment.noMethodAvailable".localized())
                    case .invalidDepositVoucher:
                        self.cartDelegate?.showWarningMessage("Snabble.invalidDepositVoucher.errorMsg".localized())
                    default:
                        if !offlineMethods.isEmpty {
                            let info = SignedCheckoutInfo(offlineMethods)
                            self.cartDelegate?.gotoPayment(paymentMethod, self.methodSelector?.selectedPaymentDetail, info, self.shoppingCart)
                        } else {
                            self.cartDelegate?.showWarningMessage("Snabble.Payment.errorStarting".localized())
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

        let start = offendingProducts.count == 1 ? "Snabble.saleStop.errorMsg.one" : "Snabble.saleStop.errorMsg"
        let msg = start.localized() + "\n\n" + offendingProducts.joined(separator: "\n")
        let alert = UIAlertController(title: "Snabble.saleStop.errorMsg.title".localized(), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default, handler: nil))
        parentVC?.present(alert, animated: true)
    }

    func setCustomAppearance(_ appearance: CustomAppearance) {
        self.checkoutButton?.setCustomAppearance(appearance)
    }
}
