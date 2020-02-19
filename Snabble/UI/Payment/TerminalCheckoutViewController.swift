//
//  TerminalCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

// TODO: merge this and OnlineCheckoutViewController, if possible?

import UIKit

public final class TerminalCheckoutViewController: UIViewController {

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var topWrapper: UIView!
    @IBOutlet private weak var topIcon: UIImageView!
    @IBOutlet private weak var iconHeight: NSLayoutConstraint!
    @IBOutlet private weak var arrowWrapper: UIView!
    @IBOutlet private weak var spinnerWrapper: UIView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var codeWrapper: UIView!
    @IBOutlet private weak var codeImage: UIImageView!
    @IBOutlet private weak var codeWidth: NSLayoutConstraint!
    @IBOutlet private weak var idWrapper: UIView!
    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    private let cart: ShoppingCart
    private weak var delegate: PaymentDelegate!

    private let process: CheckoutProcess
    private var poller: PaymentProcessPoller?
    private var initialBrightness: CGFloat = 0

    public init(_ process: CheckoutProcess, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.cart = cart
        self.delegate = delegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Snabble.Payment.confirm".localized()

        if let icon = UIImage.fromBundle(self.iconName()) {
            self.topIcon.image = icon
            self.iconHeight.constant = icon.size.height
        } else {
            self.topWrapper.isHidden = true
            self.arrowWrapper.isHidden = true
        }

        self.spinnerWrapper.isHidden = true

        let components = self.process.links.`self`.href.components(separatedBy: "/")
        let id = components.last ?? "n/a"
        self.idLabel.text = String(id.suffix(4))

        let qrCodeContent = self.process.paymentInformation?.qrCodeContent ?? "snabble:checkoutProcess:" + id

        self.codeImage.image = QRCode.generate(for: qrCodeContent, scale: 5)
        self.codeWidth.constant = self.codeImage.image?.size.width ?? 0

        self.cancelButton.setTitle("Snabble.Cancel".localized(), for: .normal)
        self.cancelButton.setTitleColor(SnabbleUI.appearance.primaryColor, for: .normal)

        self.navigationItem.hidesBackButton = true
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.initialBrightness = UIScreen.main.brightness
        if self.autoApproved {
            self.view.subviews.forEach { $0.isHidden = true }
            self.title = nil
            return
        }

        self.cancelButton.alpha = 0
        self.cancelButton.isUserInteractionEnabled = false

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.2) {
                self.cancelButton.alpha = 1
            }
            self.cancelButton.isUserInteractionEnabled = true
        }

        UIApplication.shared.isIdleTimerDisabled = true

        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate.track(.brightnessIncreased)
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewTerminalCheckout)

        if self.autoApproved {
            self.paymentFinished(true, self.process)
        } else {
            self.startPoller()
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        UIScreen.main.brightness = self.initialBrightness

        self.poller?.stop()
        self.poller = nil

        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func startPoller() {
        let poller = PaymentProcessPoller(self.process, SnabbleUI.project)

        var events = [PaymentEvent: Bool]()
        poller.waitFor([.approval, .paymentSuccess]) { event in

            UIView.animate(withDuration: 0.25) {
                self.arrowWrapper.isHidden = true
                self.codeWrapper.isHidden = true
                self.codeImage.isHidden = true
                self.spinnerWrapper.isHidden = false
                self.stackView.layoutIfNeeded()
            }

            events.merge(event, uniquingKeysWith: { bool1, _ in bool1 })

            if let approval = events[.approval], approval == false {
                self.paymentFinished(false, poller.updatedProcess)
                return
            }

            if let approval = events[.approval], let paymentSuccess = events[.paymentSuccess] {
                self.paymentFinished(approval && paymentSuccess, poller.updatedProcess)
            }
        }
        self.poller = poller
    }

    @IBAction private func cancelButtonTapped(_ sender: UIButton) {
        self.poller?.stop()
        self.poller = nil

        self.delegate.track(.paymentCancelled)

        self.process.abort(SnabbleUI.project) { result in
            switch result {
            case .success:
                self.delegate.track(.paymentCancelled)

                if let cartVC = self.navigationController?.viewControllers.first(where: { $0 is ShoppingCartViewController}) {
                    self.navigationController?.popToViewController(cartVC, animated: true)
                } else {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            case .failure:
                let alert = UIAlertController(title: "Snabble.Payment.cancelError.title".localized(),
                                              message: "Snabble.Payment.cancelError.message".localized(),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
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
        }
        self.delegate.paymentFinished(success, self.cart, process)
    }

    private var autoApproved: Bool {
        return self.process.paymentApproval == true && self.process.supervisorApproval == true
    }

    private func iconName() -> String {
        let project = SnabbleUI.project.id
        return "Checkout/\(project)/checkout-online"
    }
}
