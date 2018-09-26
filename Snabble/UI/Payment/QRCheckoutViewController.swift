//
//  QRCheckoutViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

class QRCheckoutViewController: UIViewController {

    @IBOutlet weak var qrCodeView: UIImageView!
    @IBOutlet weak var explanation1: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var qrCodeWidth: NSLayoutConstraint!
    @IBOutlet weak var checkoutIdLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    private var initialBrightness: CGFloat = 0
    private var process: CheckoutProcess
    private var poller: PaymentProcessPoller?
    private weak var cart: ShoppingCart!
    private weak var delegate: PaymentDelegate!

    init(_ process: CheckoutProcess, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.cart = cart
        self.process = process
        self.delegate = delegate

        super.init(nibName: nil, bundle: Snabble.bundle)

        self.title = "Snabble.QRCode.title".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true

        self.checkoutIdLabel.text = "Snabble.Checkout.ID".localized() + ": " + String(process.links.`self`.href.suffix(4))
        self.cancelButton.setTitle("Snabble.Cancel".localized(), for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
        }

        let total = PriceFormatter.format(self.process.checkoutInfo.price.price)
        self.totalPriceLabel.text = "Snabble.QRCode.total".localized() + "\(total)"
        self.explanation1.text = "Snabble.QRCode.showThisCode".localized()

        let qrCodeContent = self.process.paymentInformation?.qrCodeContent ?? "n/a"
        // print("QR code: \(qrCodeContent)")
        self.qrCodeView.image = QRCode.generate(for: qrCodeContent, scale: 5)
        self.qrCodeWidth.constant = self.qrCodeView.image?.size.width ?? 0

        self.poller = PaymentProcessPoller(self.process, SnabbleUI.project)
        self.poller?.waitForPayment { success in
            self.poller = nil
            self.paymentFinished(success)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewQRCodeCheckout)
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIScreen.main.brightness = self.initialBrightness
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.poller?.stop()
        self.poller = nil

        self.delegate.track(.paymentCancelled)

        self.process.abort(SnabbleUI.project) { process, error in
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    @objc private func paymentFinished(_ success: Bool) {
        self.poller = nil

        self.delegate.paymentFinished(success, self.cart)
    }

}
