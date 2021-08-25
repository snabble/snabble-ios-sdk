//
//  CustomerCardCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public final class CustomerCardCheckoutViewController: UIViewController {
    @IBOutlet private var topWrapper: UIView!
    @IBOutlet private var topIcon: UIImageView!
    @IBOutlet private var iconHeight: NSLayoutConstraint!
    @IBOutlet private var arrowWrapper: UIView!
    @IBOutlet private var codeWrapper: UIView!

    @IBOutlet private var eanView: EANView!

    @IBOutlet private var paidButton: UIButton!

    private var initialBrightness: CGFloat = 0

    private let cart: ShoppingCart
    private weak var delegate: PaymentDelegate?
    private var process: CheckoutProcess?
    private var rawJson: [String: Any]?

    public init(_ process: CheckoutProcess?, _ rawJson: [String: Any]?, _ cart: ShoppingCart, _ delegate: PaymentDelegate?) {
        self.process = process
        self.rawJson = rawJson
        self.cart = cart
        self.delegate = delegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = L10n.Snabble.Checkout.payAtCashRegister
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.eanView.barcode = self.cart.customerCard

        self.paidButton.makeSnabbleButton()
        self.paidButton.setTitle(L10n.Snabble.QRCode.didPay, for: .normal)
        self.paidButton.alpha = 0
        self.paidButton.isUserInteractionEnabled = false

        self.arrowWrapper.isHidden = true
        self.topWrapper.isHidden = true
        SnabbleUI.getAsset(.checkoutOffline, bundlePath: "Checkout/\(SnabbleUI.project.id)/checkout-offline") { img in
            if let img = img {
                self.topIcon.image = img
                self.iconHeight.constant = img.size.height
                self.topWrapper.isHidden = false
                self.arrowWrapper.isHidden = false
            }
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.delegate?.track(.viewCustomerCardCheckout)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate?.track(.brightnessIncreased)
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.2) {
                self.paidButton.alpha = 1
            }
            self.paidButton.isUserInteractionEnabled = true
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness
    }

    @IBAction private func paidButtonTapped(_ sender: UIButton) {
        self.cart.removeAll(endSession: true)

        SnabbleAPI.fetchAppUserData(SnabbleUI.project.id)
        self.delegate?.paymentFinished(true, self.cart, self.process, self.rawJson)
    }
}
