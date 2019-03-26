//
//  SepaCheckoutViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

final class SepaCheckoutViewController: UIViewController {

    @IBOutlet weak var codeImage: UIImageView!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var waitLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var codeWidth: NSLayoutConstraint!
    
    private weak var cart: ShoppingCart!
    private weak var delegate: PaymentDelegate!

    private var process: CheckoutProcess
    private var poller: PaymentProcessPoller?

    init(_ process: CheckoutProcess, _ data: PaymentMethodData, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.cart = cart
        self.delegate = delegate
        
        super.init(nibName: nil, bundle: Snabble.bundle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.Payment.confirm".localized()

        self.explanationLabel.text = "Snabble.Payment.presentCode".localized()
        self.waitLabel.text = "Snabble.Payment.waiting".localized()

        let components = process.links.`self`.href.components(separatedBy: "/")
        let id = components.last ?? "n/a"

        self.codeImage.image = QRCode.generate(for: id, scale: 5)
        self.codeWidth.constant = self.codeImage.image?.size.width ?? 0

        self.cancelButton.setTitle("Snabble.Cancel".localized(), for: .normal)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewSepaCheckout)

        self.poller = PaymentProcessPoller(self.process, SnabbleUI.project, self.cart.config.shop)

        self.poller?.waitFor([.approval]) { events in
            if let success = events[.approval] {
                self.paymentFinished(success)
            } else {
                self.paymentFinished(false)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.poller?.stop()
        self.poller = nil

        self.delegate.track(.paymentCancelled)
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.poller?.stop()
        self.poller = nil

        self.delegate.track(.paymentCancelled)

        self.process.abort(SnabbleUI.project) { result in
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    private func paymentFinished(_ success: Bool) {
        self.poller = nil
        if success {
            self.cart.removeAll(endSession: true)
        }
        self.delegate.paymentFinished(success, self.cart)
    }
}
