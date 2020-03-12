//
//  BaseCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public class BaseCheckoutViewController: UIViewController {

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

    let process: CheckoutProcess
    private var poller: PaymentProcessPoller?
    private var initialBrightness: CGFloat = 0

    init(_ process: CheckoutProcess, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.cart = cart
        self.delegate = delegate

        super.init(nibName: "BaseCheckoutViewController", bundle: SnabbleBundle.main)
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

        self.topWrapper.isHidden = true
        self.arrowWrapper.isHidden = true
        AssetManager.instance.getAsset(.checkoutOnline, bundlePath: "Checkout/\(SnabbleUI.project.id)/checkout-online") { img in
            if let img = img {
                self.topIcon.image = img
                self.iconHeight.constant = img.size.height
                self.topWrapper.isHidden = false
                self.arrowWrapper.isHidden = false
            }
        }

        self.spinnerWrapper.isHidden = true

        let components = self.process.links.`self`.href.components(separatedBy: "/")
        let id = components.last ?? "n/a"
        self.idLabel.text = String(id.suffix(4))

        let qrCodeContent = self.qrCodeContent(self.process, id)
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

        self.setSpinnerAppearance()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(self.viewEvent)

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

    // MARK: - child classes must override these methods

    func qrCodeContent(_ process: CheckoutProcess, _ id: String) -> String {
        fatalError("child classes must override this")
    }

    var viewEvent: AnalyticsEvent {
        fatalError("child classes must override this")
    }

    var waitForEvents: [PaymentEvent] {
        fatalError("child classes must override this")
    }

    var autoApproved: Bool {
        fatalError("child classes must override this")
    }

    // MARK: - event polling
    private func startPoller() {
        let poller = PaymentProcessPoller(self.process, SnabbleUI.project)

        var events = [PaymentEvent: Bool]()

        let waitForEvents = self.waitForEvents
        let waitForApproval = waitForEvents.contains(.approval)

        poller.waitFor(waitForEvents) { event in
            UIView.animate(withDuration: 0.25) {
                self.arrowWrapper.isHidden = true
                self.codeWrapper.isHidden = true
                self.codeImage.isHidden = true
                self.spinnerWrapper.isHidden = false
                self.stackView.layoutIfNeeded()
            }

            events.merge(event, uniquingKeysWith: { bool1, _ in bool1 })

            if waitForApproval {
                if let approval = events[.approval], approval == false {
                    self.paymentFinished(false, poller.updatedProcess)
                    return
                }

                if let approval = events[.approval], let paymentSuccess = events[.paymentSuccess] {
                    self.paymentFinished(approval && paymentSuccess, poller.updatedProcess)
                }
            } else {
                if let paymentSuccess = events[.paymentSuccess] {
                    self.paymentFinished(paymentSuccess, poller.updatedProcess)
                }
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
}

// MARK: - Appearance change
extension BaseCheckoutViewController {
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }

            self.setSpinnerAppearance()
        }
    }

    private func setSpinnerAppearance() {
        if #available(iOS 13.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                self.spinner.style = .white
            } else {
                self.spinner.style = .gray
            }
        }
    }
}
