//
//  InflightCheckoutContinuationViewController.swift
//  Snabble
//
//  Created by Gereon Steffens on 07.04.22.
//

import UIKit

public final class InflightCheckoutContinuationViewController: UIViewController {
    private let spinner = UIActivityIndicatorView()
    private let label = UILabel()

    public weak var paymentDelegate: PaymentDelegate?
    public var shoppingCart: ShoppingCart?

    override public func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        title = L10n.Snabble.Payment.confirm

        view.backgroundColor = .systemBackground

        if #available(iOS 13.0, *) {
            spinner.style = .medium
        } else {
            spinner.style = .gray
        }
        spinner.startAnimating()

        label.text = L10n.Snabble.PaymentContinuation.message
        label.numberOfLines = 0
        label.useDynamicFont(forTextStyle: .body)

        let stackview = UIStackView(arrangedSubviews: [ spinner, label ])
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.axis = .vertical
        stackview.spacing = 16
        stackview.alignment = .center

        view.addSubview(stackview)

        NSLayoutConstraint.activate([
            stackview.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        if let inFlightCheckout = Snabble.inFlightCheckout {
            continueInFlightCheckout(with: inFlightCheckout)
        }
    }

    private func continueInFlightCheckout(with inFlightCheckout: Snabble.InFlightCheckout) {
        guard let project = inFlightCheckout.shop.project else {
            return
        }

        CheckoutProcess.fetch(for: project, url: inFlightCheckout.url) { result in
            switch result.result {
            case .success(let process):
                var cart = inFlightCheckout.cart
                if cart.uuid == self.shoppingCart?.uuid {
                    cart = self.shoppingCart!
                }
                let checkoutVC = PaymentProcess.checkoutViewController(for: process,
                                                                       shop: inFlightCheckout.shop,
                                                                       cart: cart,
                                                                       paymentDelegate: self.paymentDelegate)
                if let checkout = checkoutVC {
                    self.navigationController?.pushViewController(checkout, animated: true)
                }
            case .failure(let error):
                print("can't get in-flight checkout process: \(error)")
            }
        }
    }
}
