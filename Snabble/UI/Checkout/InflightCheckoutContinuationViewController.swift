//
//  InflightCheckoutContinuationViewController.swift
//  Snabble
//
//  Created by Gereon Steffens on 07.04.22.
//

import UIKit

public final class InFlightCheckoutContinuationViewController: UIViewController {
    private weak var activityIndicatorView: UIActivityIndicatorView?
    private weak var textLabel: UILabel?

    public weak var paymentDelegate: PaymentDelegate?
    public var shoppingCart: ShoppingCart?

    public let inFlightCheckout: Snabble.InFlightCheckout

    public init(inFlightCheckout: Snabble.InFlightCheckout) {
        self.inFlightCheckout = inFlightCheckout

        super.init(nibName: nil, bundle: nil)

        title = L10n.Snabble.Payment.confirm
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)

        if #available(iOS 15, *) {
            view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        view.backgroundColor = .systemBackground

        let activityIndicatorView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicatorView = .init(style: .medium)
        } else {
            activityIndicatorView = .init(style: .gray)
        }
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()

        let textLabel = UILabel()
        textLabel.text = L10n.Snabble.PaymentContinuation.message
        textLabel.numberOfLines = 0
        textLabel.font = UIFont.preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true

        let stackview = UIStackView(arrangedSubviews: [ activityIndicatorView, textLabel ])
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.axis = .vertical
        stackview.spacing = 16
        stackview.alignment = .center

        view.addSubview(stackview)

        self.textLabel = textLabel
        self.activityIndicatorView = activityIndicatorView

        NSLayoutConstraint.activate([
            stackview.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackview.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            stackview.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            stackview.topAnchor.constraint(greaterThanOrEqualTo: view.readableContentGuide.topAnchor),
            stackview.bottomAnchor.constraint(lessThanOrEqualTo: view.readableContentGuide.bottomAnchor)
        ])

        self.view = view
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(true, animated: false)

        continueInFlightCheckout(with: inFlightCheckout)
    }

    private func continueInFlightCheckout(with inFlightCheckout: Snabble.InFlightCheckout) {
        guard let project = inFlightCheckout.shop.project else {
            navigationController?.popViewController(animated: true)
            return
        }
        CheckoutProcess.fetch(for: project, url: inFlightCheckout.url) { [weak self] result in
            switch result.result {
            case .success(let process):
                self?.activityIndicatorView?.stopAnimating()
                var cart = inFlightCheckout.cart
                if let shoppingCart = self?.shoppingCart, cart.uuid == shoppingCart.uuid {
                    cart = shoppingCart
                }
                let checkoutVC = PaymentProcess.checkoutViewController(for: process,
                                                                       shop: inFlightCheckout.shop,
                                                                       cart: cart,
                                                                       paymentDelegate: self?.paymentDelegate)
                if let checkout = checkoutVC {
                    self?.navigationController?.pushViewController(checkout, animated: true)
                }
            case .failure(let error):
                print("can't get in-flight checkout process: \(error)")
            }
        }
    }
}
