//
//  CustomerCardCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public final class CustomerCardCheckoutViewController: UIViewController {

    @IBOutlet private weak var topWrapper: UIView!
    @IBOutlet private weak var topIcon: UIImageView!
    @IBOutlet private weak var iconHeight: NSLayoutConstraint!
    @IBOutlet private weak var arrowWrapper: UIView!
    @IBOutlet private weak var codeWrapper: UIView!

    @IBOutlet private weak var eanView: EANView!

    @IBOutlet private weak var paidButton: UIButton!

    private var initialBrightness: CGFloat = 0

    private weak var cart: ShoppingCart!
    private weak var delegate: PaymentDelegate!
    private var process: CheckoutProcess?

    public init(_ process: CheckoutProcess?, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.cart = cart
        self.delegate = delegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.Checkout.payAtCashRegister".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.eanView.barcode = self.cart.customerCard

        self.paidButton.makeSnabbleButton()
        self.paidButton.setTitle("Snabble.QRCode.didPay".localized(), for: .normal)
        self.paidButton.alpha = 0
        self.paidButton.isUserInteractionEnabled = false

        #warning("fixme too")
        self.arrowWrapper.isHidden = true
        self.topWrapper.isHidden = true
        AssetManager.instance.getAsset("checkout-offline", "Checkout/\(SnabbleUI.project.id)") { img in
            if let img = img {
                self.topIcon.image = img
                self.iconHeight.constant = img.size.height
                self.topWrapper.isHidden = false
                self.arrowWrapper.isHidden = false
            }
        }

//        if let icon = AssetManager.instance.getAsset("checkout-offline", "Checkout/\(SnabbleUI.project.id)") {
//            self.topIcon.image = icon
//            self.iconHeight.constant = icon.size.height
//        } else {
//            self.topWrapper.isHidden = true
//            self.arrowWrapper.isHidden = true
//        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.delegate.track(.viewCustomerCardCheckout)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate.track(.brightnessIncreased)
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
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)

        self.delegate.paymentFinished(true, self.cart, self.process)
    }

}
