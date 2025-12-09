//
//  CustomerCardCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

final class CustomerCardCheckoutViewController: UIViewController {
    private weak var iconWrapper: UIView?
    private weak var iconImageView: UIImageView?
    private weak var arrowWrapper: UIView?
    private weak var codeWrapper: UIView?
    private weak var codeView: EANView?
    private weak var paidButton: UIButton?
    private var iconImageHeight: NSLayoutConstraint?

    private var initialBrightness: CGFloat = 0
    private let arrowIconHeight: CGFloat = 30

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

        self.title = Asset.localizedString(forKey: "Snabble.Checkout.payAtCashRegister")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)
        contentView.backgroundColor = .systemBackground
        if #available(iOS 15, *) {
            contentView.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false

        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide

        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false

        let paidButton = UIButton(type: .system)
        paidButton.translatesAutoresizingMaskIntoConstraints = false
        paidButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        paidButton.titleLabel?.adjustsFontForContentSizeCategory = true
        paidButton.makeSnabbleButton()
        paidButton.setTitle(Asset.localizedString(forKey: "Snabble.QRCode.didPay"), for: .normal)
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
        arrowIcon.image = Asset.image(named: "SnabbleSDK/arrow-up")
        arrowIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true

        let codeWrapper = UIView()
        codeWrapper.translatesAutoresizingMaskIntoConstraints = false

        let codeView = EANView()
        codeView.translatesAutoresizingMaskIntoConstraints = false
        codeView.backgroundColor = .systemBackground

        contentView.addSubview(scrollView)
        scrollView.addSubview(wrapperView)

        wrapperView.addLayoutGuide(stackViewLayout)
        wrapperView.addSubview(stackView)
        wrapperView.addSubview(paidButton)

        stackView.addArrangedSubview(iconWrapper)
        stackView.addArrangedSubview(arrowWrapper)
        stackView.addArrangedSubview(codeWrapper)

        iconWrapper.addSubview(iconImageView)
        arrowWrapper.addSubview(arrowIcon)
        codeWrapper.addSubview(codeView)

        NSLayoutConstraint.activate([
            frameLayoutGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            frameLayoutGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            frameLayoutGuide.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            frameLayoutGuide.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            frameLayoutGuide.widthAnchor.constraint(equalTo: contentLayoutGuide.widthAnchor),

            contentLayoutGuide.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor),
            contentLayoutGuide.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            contentLayoutGuide.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor),
            contentLayoutGuide.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor),
            wrapperView.heightAnchor.constraint(greaterThanOrEqualTo: frameLayoutGuide.heightAnchor),

            paidButton.heightAnchor.constraint(equalToConstant: 48),
            paidButton.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -16),
            paidButton.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            paidButton.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),

            stackViewLayout.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            stackViewLayout.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            stackViewLayout.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),
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

        setupIcons()

        registerForTraitChanges([UITraitUserInterfaceStyle.self,
                                 UITraitHorizontalSizeClass.self,
                                 UITraitVerticalSizeClass.self]) { (self: Self, _: UITraitCollection) in
            self.setupIcons()
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

    private func setupIcons() {
        SnabbleCI.getAsset(.checkoutOffline, bundlePath: "Checkout/\(SnabbleCI.project.id)/checkout-offline") { img in
            if let img = img {
                self.iconImageView?.image = img
                self.iconImageHeight?.constant = img.size.height
                self.iconWrapper?.isHidden = false
                let scaledArrowWrapperHeight = UIFontMetrics.default.scaledValue(for: self.arrowIconHeight)
                self.arrowWrapper?.heightAnchor.constraint(equalToConstant: scaledArrowWrapperHeight).usingPriority(.defaultHigh + 1).isActive = true
                self.arrowWrapper?.isHidden = false
            }
        }
    }

    @objc private func paidButtonTapped(_ sender: Any) {
        self.cart.removeAll(endSession: true, keepBackup: true)

        let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: cart, checkoutProcess: process)
        checkoutSteps.paymentDelegate = delegate
        self.navigationController?.pushViewController(checkoutSteps, animated: true)
    }
}
