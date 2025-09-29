//
//  QRCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import SnabbleCore
import SnabbleAssetProviding

final class QRCheckoutViewController: UIViewController {

    private weak var checkoutIdLabel: UILabel?
    private weak var totalPriceLabel: UILabel?
    private weak var explanationUpperLabel: UILabel?
    private weak var qrCodeView: UIImageView?
    private weak var explanationBottomLabel: UILabel?
    private weak var cancelButton: UIButton?

    private var qrCodeWidth: NSLayoutConstraint?
    private var initialBrightness: CGFloat = 0
    private let process: CheckoutProcess
    private var poller: PaymentProcessPoller?
    private let cart: ShoppingCart
    private let shop: Shop
    weak var delegate: PaymentDelegate?

    private var customLabel: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        return label
    }

    public init(shop: Shop,
                checkoutProcess: CheckoutProcess,
                cart: ShoppingCart) {
        self.shop = shop
        self.cart = cart
        self.process = checkoutProcess

        super.init(nibName: nil, bundle: nil)

        title = Asset.localizedString(forKey: "Snabble.QRCode.title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)
        if #available(iOS 15, *) {
            contentView.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }
        contentView.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false

        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide

        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false

        let checkoutIdLabel = customLabel
        checkoutIdLabel.font = .preferredFont(forTextStyle: .footnote)

        let stackViewLayout = UILayoutGuide()

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 16

        let totalPriceLabel = customLabel
        totalPriceLabel.font = .preferredFont(forTextStyle: .body, weight: .medium)

        let explanationUpperLabel = customLabel
        explanationUpperLabel.font = .preferredFont(forTextStyle: .body, weight: .light)

        let qrCodeView = UIImageView()
        qrCodeView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeView.contentMode = .scaleToFill
        qrCodeView.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        qrCodeView.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

        let explanationBottomLabel = customLabel
        explanationBottomLabel.font = .preferredFont(forTextStyle: .caption2)

        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle(Asset.localizedString(forKey: "Snabble.cancel"), for: .normal)
        cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        cancelButton.titleLabel?.textAlignment = .center
        cancelButton.isEnabled = true
        cancelButton.isUserInteractionEnabled = true
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
        cancelButton.makeSnabbleButton()

        contentView.addSubview(scrollView)
        scrollView.addSubview(wrapperView)

        wrapperView.addSubview(checkoutIdLabel)
        wrapperView.addLayoutGuide(stackViewLayout)
        wrapperView.addSubview(stackView)
        wrapperView.addSubview(cancelButton)

        stackView.addArrangedSubview(totalPriceLabel)
        stackView.addArrangedSubview(explanationUpperLabel)
        stackView.addArrangedSubview(qrCodeView)
        stackView.addArrangedSubview(explanationBottomLabel)

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

            checkoutIdLabel.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 8),
            checkoutIdLabel.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            checkoutIdLabel.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),

            cancelButton.leadingAnchor.constraint(equalTo: wrapperView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: wrapperView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cancelButton.bottomAnchor.constraint(equalTo: wrapperView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),

            stackViewLayout.topAnchor.constraint(equalTo: checkoutIdLabel.bottomAnchor),
            stackViewLayout.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            stackViewLayout.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),
            stackViewLayout.bottomAnchor.constraint(equalTo: cancelButton.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: stackViewLayout.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackViewLayout.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackViewLayout.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackViewLayout.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackViewLayout.bottomAnchor),

            qrCodeView.widthAnchor.constraint(equalToConstant: 0).usingVariable(&qrCodeWidth),
            qrCodeView.heightAnchor.constraint(equalTo: qrCodeView.widthAnchor)
        ])
        self.checkoutIdLabel = checkoutIdLabel
        self.totalPriceLabel = totalPriceLabel
        self.explanationUpperLabel = explanationUpperLabel
        self.explanationBottomLabel = explanationBottomLabel
        self.qrCodeView = qrCodeView
        self.cancelButton = cancelButton

        self.view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        setupLabels()
        setupQrCode()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate?.track(.brightnessIncreased)
        }

        self.startPoller()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate?.track(.viewQRCodeCheckout)
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIScreen.main.brightness = self.initialBrightness
        self.poller?.stop()
        self.poller = nil
    }

    private func setupQrCode() {
        let qrCodeContent = self.process.paymentInformation?.qrCodeContent ?? "n/a"
        if let qrImage = QRCode.generate(for: qrCodeContent, scale: 5) {
            qrCodeView?.image = qrImage
            qrCodeWidth?.constant = qrImage.size.width
        }
    }

    private func setupLabels() {
        self.checkoutIdLabel?.text = Asset.localizedString(forKey: "Snabble.Checkout.id") + ": " + String(process.links._self.href.suffix(4))

        let formatter = PriceFormatter(shop.project ?? SnabbleCI.project)
        // if we have a valid checkoutInfo, use the total from that, else what we've calculated in the cart
        let lineItems = process.pricing.lineItems.count
        let total = lineItems > 0 ? process.pricing.price.price : self.cart.total

        let formattedTotal = formatter.format(total ?? 0)

        self.totalPriceLabel?.text = Asset.localizedString(forKey: "Snabble.QRCode.total") + "\(formattedTotal)"
        self.explanationUpperLabel?.text = Asset.localizedString(forKey: "Snabble.QRCode.showThisCode")
        self.explanationBottomLabel?.text = Asset.localizedString(forKey: "Snabble.QRCode.priceMayDiffer")
    }

    private func startPoller() {
        let poller = PaymentProcessPoller(self.process, SnabbleCI.project)
        poller.waitFor([.paymentSuccess]) { events in
            if let success = events[.paymentSuccess] {
                Task { @MainActor in
                    self.paymentFinished(success, poller.updatedProcess)
                }
            }
        }
        self.poller = poller
    }

    @objc private func cancelButtonTapped(_ sender: UIButton) {
        guard self.poller != nil else { return }
        
        self.poller?.stop()
        self.poller = nil

        sender.isEnabled = false

        self.process.abort(SnabbleCI.project) { result in
            switch result {
            case .success:
                Snabble.clearInFlightCheckout()
                self.cart.generateNewUUID()

                Task { @MainActor in
                    self.delegate?.track(.paymentCancelled)

                    if let cartVC = self.navigationController?.viewControllers.first(where: { $0 is ShoppingCartViewController}) {
                        self.navigationController?.popToViewController(cartVC, animated: true)
                    } else {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            case .failure:
                Task { @MainActor in
                    let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.Payment.CancelError.title"),
                                                  message: Asset.localizedString(forKey: "Snabble.Payment.CancelError.message"),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
                        self.startPoller()
                        sender.isEnabled = true
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @MainActor private func paymentFinished(_ success: Bool, _ process: CheckoutProcess) {
        self.poller = nil

        if success {
            self.cart.removeAll(endSession: true, keepBackup: false)
        } else {
            self.cart.generateNewUUID()
        }

        let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: cart, checkoutProcess: process)
        checkoutSteps.paymentDelegate = delegate
        self.navigationController?.pushViewController(checkoutSteps, animated: true)
    }
}
