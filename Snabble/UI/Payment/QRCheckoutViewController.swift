//
//  QRCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)
        contentView.backgroundColor = .systemBackground

        let checkoutIdLabel = customLabel
        checkoutIdLabel.font = UIFont.systemFont(ofSize: 13)

        let totalPriceLabel = customLabel
        totalPriceLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)

        let explanationUpperLabel = customLabel
        explanationUpperLabel.font = UIFont.systemFont(ofSize: 17, weight: .light)
        explanationUpperLabel.lineBreakMode = .byWordWrapping
        explanationUpperLabel.numberOfLines = 0

        let qrCodeView = UIImageView()
        qrCodeView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeView.contentMode = .scaleToFill
        qrCodeView.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        qrCodeView.setContentHuggingPriority(.defaultLow + 1, for: .vertical)

        let explanationBottomLabel = customLabel
        explanationUpperLabel.font = UIFont.systemFont(ofSize: 11)
        explanationBottomLabel.numberOfLines = 0

        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle(L10n.Snabble.cancel, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        cancelButton.isEnabled = true
        cancelButton.isUserInteractionEnabled = true
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside)
        cancelButton.makeSnabbleButton()

        contentView.addSubview(checkoutIdLabel)
        contentView.addSubview(totalPriceLabel)
        contentView.addSubview(explanationUpperLabel)
        contentView.addSubview(qrCodeView)
        contentView.addSubview(explanationBottomLabel)
        contentView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            checkoutIdLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            checkoutIdLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkoutIdLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            qrCodeView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            qrCodeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            qrCodeView.widthAnchor.constraint(equalToConstant: 0).usingVariable(&qrCodeWidth),
            qrCodeView.heightAnchor.constraint(equalTo: qrCodeView.widthAnchor),

            explanationUpperLabel.bottomAnchor.constraint(equalTo: qrCodeView.topAnchor, constant: -16),
            explanationUpperLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            explanationUpperLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            totalPriceLabel.bottomAnchor.constraint(equalTo: explanationUpperLabel.topAnchor, constant: -16),
            totalPriceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            totalPriceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            explanationBottomLabel.topAnchor.constraint(equalTo: qrCodeView.bottomAnchor, constant: 16),
            explanationBottomLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            explanationBottomLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            cancelButton.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        self.view = contentView
        self.checkoutIdLabel = checkoutIdLabel
        self.totalPriceLabel = totalPriceLabel
        self.explanationUpperLabel = explanationUpperLabel
        self.qrCodeView = qrCodeView
        self.cancelButton = cancelButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.title = L10n.Snabble.QRCode.title

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
            //self.qrCodeView?.widthAnchor.constraint(equalToConstant: qrImage.size.width).isActive = true
        }
    }

    private func setupLabels() {
        self.checkoutIdLabel?.text = L10n.Snabble.Checkout.id + ": " + String(process.links._self.href.suffix(4))

        let formatter = PriceFormatter(SnabbleUI.project)
        // if we have a valid checkoutInfo, use the total from that, else what we've calculated in the cart
        let lineItems = self.process.pricing.lineItems.count
        let total = lineItems > 0 ? self.process.pricing.price.price : self.cart.total

        let formattedTotal = formatter.format(total ?? 0)

        self.totalPriceLabel?.text = L10n.Snabble.QRCode.total + "\(formattedTotal)"
        self.explanationUpperLabel?.text = L10n.Snabble.QRCode.showThisCode
        self.explanationBottomLabel?.text = L10n.Snabble.QRCode.priceMayDiffer
    }

    private func startPoller() {
        let poller = PaymentProcessPoller(self.process, SnabbleUI.project)
        poller.waitFor([.paymentSuccess]) { events in
            if let success = events[.paymentSuccess] {
                self.paymentFinished(success, poller.updatedProcess)
            }
        }
        self.poller = poller
    }

    @objc private func cancelButtonTapped(_ sender: UIButton) {
        self.poller?.stop()
        self.poller = nil

        self.process.abort(SnabbleUI.project) { result in
            switch result {
            case .success:
                Snabble.clearInFlightCheckout()
                self.cart.generateNewUUID()
                self.delegate?.track(.paymentCancelled)

                if let cartVC = self.navigationController?.viewControllers.first(where: { $0 is ShoppingCartViewController}) {
                    self.navigationController?.popToViewController(cartVC, animated: true)
                } else {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            case .failure:
                let alert = UIAlertController(title: L10n.Snabble.Payment.CancelError.title,
                                              message: L10n.Snabble.Payment.CancelError.message,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L10n.Snabble.ok, style: .default) { _ in
                    self.startPoller()
                })
                self.present(alert, animated: true)
            }
        }
    }

    private func paymentFinished(_ success: Bool, _ process: CheckoutProcess) {
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
