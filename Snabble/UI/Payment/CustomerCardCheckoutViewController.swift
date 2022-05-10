//
//  CustomerCardCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

final class CustomerCardCheckoutViewController: UIViewController {
    private weak var iconWrapper: UIView?
    private weak var iconImageView: UIImageView?
    private weak var arrowWrapper: UIView?
    private weak var codeWrapper: UIView?
    private weak var codeView: EANView?
    private weak var paidButton: UIButton?
    private var iconImageHeight: NSLayoutConstraint?

    private var initialBrightness: CGFloat = 0

    private let cart: ShoppingCart
    weak var delegate: PaymentDelegate?
    private let process: CheckoutProcess
    private let shop: Shop

    private var customImage: UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow + 2, for: .vertical)
        return imageView
    }

    public init(shop: Shop,
                checkoutProcess: CheckoutProcess,
                cart: ShoppingCart) {
        self.process = checkoutProcess
        self.cart = cart
        self.shop = shop

        super.init(nibName: nil, bundle: nil)

        self.title = L10n.Snabble.Checkout.payAtCashRegister
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)
        contentView.backgroundColor = .systemBackground

        let paidButton = UIButton(type: .system)
        paidButton.translatesAutoresizingMaskIntoConstraints = false
        paidButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        paidButton.makeSnabbleButton()
        paidButton.setTitle(L10n.Snabble.QRCode.didPay, for: .normal)
        paidButton.alpha = 0
        paidButton.isUserInteractionEnabled = false
        paidButton.addTarget(self, action: #selector(paidButtonTapped(_:)), for: .touchUpInside)

        let stackViewLayout = UILayoutGuide()

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 16

        let iconWrapper = UIView()
        iconWrapper.translatesAutoresizingMaskIntoConstraints = false

        let iconImageView = customImage

        let arrowWrapper = UIView()
        arrowWrapper.translatesAutoresizingMaskIntoConstraints = false

        let arrowIcon = customImage
        arrowIcon.image = Asset.SnabbleSDK.arrowUp.image

        let codeWrapper = UIView()
        codeWrapper.translatesAutoresizingMaskIntoConstraints = false

        let codeView = EANView()
        codeView.translatesAutoresizingMaskIntoConstraints = false
        codeView.backgroundColor = .systemBackground

        contentView.addLayoutGuide(stackViewLayout)
        contentView.addSubview(stackView)
        contentView.addSubview(paidButton)

        stackView.addArrangedSubview(iconWrapper)
        stackView.addArrangedSubview(arrowWrapper)
        stackView.addArrangedSubview(codeWrapper)

        iconWrapper.addSubview(iconImageView)
        arrowWrapper.addSubview(arrowIcon)
        codeWrapper.addSubview(codeView)

        NSLayoutConstraint.activate([
            paidButton.heightAnchor.constraint(equalToConstant: 48),
            paidButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            paidButton.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            paidButton.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            stackViewLayout.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            stackViewLayout.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackViewLayout.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackViewLayout.bottomAnchor.constraint(equalTo: paidButton.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: stackViewLayout.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackViewLayout.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackViewLayout.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackViewLayout.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackViewLayout.bottomAnchor),

            iconImageView.centerXAnchor.constraint(equalTo: iconWrapper.centerXAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 0).usingVariable(&iconImageHeight),
            iconImageView.topAnchor.constraint(equalTo: iconWrapper.topAnchor, constant: 16),
            iconImageView.bottomAnchor.constraint(equalTo: iconWrapper.bottomAnchor, constant: -16),

            arrowWrapper.heightAnchor.constraint(equalToConstant: 30),
            arrowIcon.leadingAnchor.constraint(equalTo: arrowWrapper.leadingAnchor),
            arrowIcon.trailingAnchor.constraint(equalTo: arrowWrapper.trailingAnchor),
            arrowIcon.topAnchor.constraint(equalTo: arrowWrapper.topAnchor),
            arrowIcon.bottomAnchor.constraint(equalTo: arrowWrapper.bottomAnchor),

            codeView.topAnchor.constraint(equalTo: codeWrapper.topAnchor, constant: 16).usingPriority(.defaultHigh + 2),
            codeView.bottomAnchor.constraint(equalTo: codeWrapper.bottomAnchor).usingPriority(.defaultHigh + 2),
            codeView.leftAnchor.constraint(equalTo: codeWrapper.leftAnchor).usingPriority(.defaultHigh + 2),
            codeView.trailingAnchor.constraint(equalTo: codeWrapper.trailingAnchor).usingPriority(.defaultHigh + 2),
            codeView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6),
            codeView.heightAnchor.constraint(equalTo: codeView.widthAnchor, multiplier: 0.35)
        ])

        self.view = contentView
        self.paidButton = paidButton
        self.iconWrapper = iconWrapper
        self.iconImageView = iconImageView
        self.arrowWrapper = arrowWrapper
        self.codeWrapper = codeWrapper
        self.codeView = codeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if Snabble.isInFlightCheckoutPending {
            self.navigationItem.hidesBackButton = true
        }

        codeView?.barcode = self.cart.customerCard

        arrowWrapper?.isHidden = true
        iconWrapper?.isHidden = true
        SnabbleUI.getAsset(.checkoutOffline, bundlePath: "Checkout/\(SnabbleUI.project.id)/checkout-offline") { img in
            if let img = img {
                self.iconImageView?.image = img
                self.iconImageHeight?.constant = img.size.height
                self.iconWrapper?.isHidden = false
                self.arrowWrapper?.isHidden = false
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.delegate?.track(.viewCustomerCardCheckout)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate?.track(.brightnessIncreased)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.2) {
                self.paidButton?.alpha = 1
            }
            self.paidButton?.isUserInteractionEnabled = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness
    }

    @objc private func paidButtonTapped(_ sender: Any) {
        self.cart.removeAll(endSession: true, keepBackup: true)

        let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: cart, checkoutProcess: process)
        checkoutSteps.paymentDelegate = delegate
        self.navigationController?.pushViewController(checkoutSteps, animated: true)
    }
}
