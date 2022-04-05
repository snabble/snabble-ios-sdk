//
//  QRCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

final class QRCheckoutViewController: UIViewController {
    @IBOutlet private var qrCodeView: UIImageView!
    @IBOutlet private var explanation1: UILabel!
    @IBOutlet private var explanation2: UILabel!
    @IBOutlet private var totalPriceLabel: UILabel!
    @IBOutlet private var qrCodeWidth: NSLayoutConstraint!
    @IBOutlet private var checkoutIdLabel: UILabel!
    @IBOutlet private var cancelButton: UIButton!

    private var initialBrightness: CGFloat = 0
    private let process: CheckoutProcess
    private var poller: PaymentProcessPoller?
    private let cart: ShoppingCart
    private let shop: Shop
    weak var delegate: PaymentDelegate?

    public init(shop: Shop,
                checkoutProcess: CheckoutProcess,
                cart: ShoppingCart) {
        self.shop = shop
        self.cart = cart
        self.process = checkoutProcess

        super.init(nibName: nil, bundle: SnabbleSDKBundle.main)

        self.title = L10n.Snabble.QRCode.title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true

        self.checkoutIdLabel.text = L10n.Snabble.Checkout.id + ": " + String(process.links._self.href.suffix(4))
        self.cancelButton.setTitle(L10n.Snabble.cancel, for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate?.track(.brightnessIncreased)
        }

        let formatter = PriceFormatter(SnabbleUI.project)
        // if we have a valid checkoutInfo, use the total from that, else what we've calculated in the cart
        let lineItems = self.process.pricing.lineItems.count
        let total = lineItems > 0 ? self.process.pricing.price.price : self.cart.total

        let formattedTotal = formatter.format(total ?? 0)

        self.totalPriceLabel.text = L10n.Snabble.QRCode.total + "\(formattedTotal)"
        self.explanation1.text = L10n.Snabble.QRCode.showThisCode
        self.explanation2.text = L10n.Snabble.QRCode.priceMayDiffer

        self.setupQrCode()

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
        self.qrCodeView.image = QRCode.generate(for: qrCodeContent, scale: 5)
        self.qrCodeWidth.constant = self.qrCodeView.image?.size.width ?? 0
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

    @IBAction private func cancelButtonTapped(_ sender: UIButton) {
        self.poller?.stop()
        self.poller = nil

        self.process.abort(SnabbleUI.project) { result in
            switch result {
            case .success:
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
