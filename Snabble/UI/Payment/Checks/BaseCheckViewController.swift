//
//  BaseCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit

// base class for SupervisorCheckViewController and GatekeeperCheckViewController

class BaseCheckViewController: UIViewController {
    private var checkoutProcess: CheckoutProcess
    private let shop: Shop
    private let shoppingCart: ShoppingCart

    private weak var processTimer: Timer?
    private var sessionTask: URLSessionTask?

    let topWrapper = UIView()
    let stackView = UIStackView()
    let iconWrapper = UIView()
    let textWrapper = UIView()
    let arrowWrapper = UIView()
    let codeWrapper = UIView()
    let idWrapper = UIView()

    private let icon = UIImageView()
    private let text = UILabel()
    private let arrow = UIImageView(image: Asset.SnabbleSDK.arrowUp.image)
    private let code = UIImageView()
    private let id = UILabel()

    private let cancelButton = UIButton()

    private var initialBrightness: CGFloat = 0

    weak var delegate: PaymentDelegate?

    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        self.shop = shop
        self.shoppingCart = shoppingCart
        self.checkoutProcess = checkoutProcess

        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Snabble.Payment.confirm

        view.backgroundColor = .systemBackground

        // set the main view components
        topWrapper.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topWrapper)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle(L10n.Snabble.cancel, for: .normal)
        cancelButton.setTitleColor(.label, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)

        view.addSubview(cancelButton)

        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            topWrapper.topAnchor.constraint(equalTo: margins.topAnchor),
            topWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topWrapper.bottomAnchor.constraint(equalTo: cancelButton.topAnchor),

            cancelButton.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -16),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // build the stackview components

        iconWrapper.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: iconWrapper.topAnchor, constant: 16),
            icon.bottomAnchor.constraint(equalTo: iconWrapper.bottomAnchor, constant: -16),
            icon.centerXAnchor.constraint(equalTo: iconWrapper.centerXAnchor)
        ])

        textWrapper.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.numberOfLines = 0
        text.textAlignment = .center
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: textWrapper.leadingAnchor),
            text.trailingAnchor.constraint(equalTo: textWrapper.trailingAnchor),
            text.topAnchor.constraint(equalTo: textWrapper.topAnchor, constant: 4),
            text.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor, constant: -4)
        ])

        arrowWrapper.addSubview(arrow)
        arrow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arrowWrapper.heightAnchor.constraint(equalToConstant: 30),
            arrow.centerXAnchor.constraint(equalTo: arrowWrapper.centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: arrowWrapper.centerYAnchor)
        ])

        codeWrapper.addSubview(code)
        code.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            code.topAnchor.constraint(equalTo: codeWrapper.topAnchor, constant: 16),
            code.bottomAnchor.constraint(equalTo: codeWrapper.bottomAnchor, constant: -16),
            code.centerXAnchor.constraint(equalTo: codeWrapper.centerXAnchor)
        ])

        idWrapper.addSubview(id)
        id.translatesAutoresizingMaskIntoConstraints = false
        id.font = .systemFont(ofSize: 13)
        NSLayoutConstraint.activate([
            idWrapper.heightAnchor.constraint(equalToConstant: 21),
            id.centerXAnchor.constraint(equalTo: idWrapper.centerXAnchor),
            id.centerYAnchor.constraint(equalTo: idWrapper.centerYAnchor)
        ])

        arrangeLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.hidesBackButton = true
        self.cancelButton.alpha = 0
        self.cancelButton.isUserInteractionEnabled = false
        self.cancelButton.addTarget(self, action: #selector(self.cancelPayment), for: .touchUpInside)

        self.initialBrightness = UIScreen.main.brightness
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.2) {
                self.cancelButton.alpha = 1
            }
            self.cancelButton.isUserInteractionEnabled = true
        }

        UIApplication.shared.isIdleTimerDisabled = true

        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate?.track(.brightnessIncreased)
        }

        self.setIcon()

        let codeContent = codeContent()
        self.code.image = renderCode(codeContent)

        let onlineMessageKey = "Snabble.Payment.Online.message"
        let onlineMessage = SnabbleAPI.l10n(onlineMessageKey)
        self.text.text = onlineMessage
        // hide if there is no text/translation
        self.textWrapper.isHidden = onlineMessage == onlineMessageKey.uppercased()

        self.id.text = String(checkoutProcess.id.suffix(4))

        self.startTimer()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - override points
    func arrangeLayout() {
        fatalError("clients must override")
    }

    func renderCode(_ content: String) -> UIImage? {
        fatalError("clients must override")
    }

    func checkContinuation(for process: CheckoutProcess) -> CheckResult {
        fatalError("clients must override")
    }

    private func codeContent() -> String {
        switch checkoutProcess.rawPaymentMethod {
        case .gatekeeperTerminal:
            let handoverInformation = checkoutProcess.paymentInformation?.handoverInformation
            return handoverInformation ?? "snabble:checkoutProcess:\(checkoutProcess.id)"
        default:
            return checkoutProcess.id
        }
    }

    private func setIcon() {
        let asset: ImageAsset
        let bundlePath: String
        switch checkoutProcess.rawPaymentMethod {
        case .qrCodeOffline, .customerCardPOS:
            asset = .checkoutOffline
            bundlePath = "Checkout/\(SnabbleUI.project.id)/checkout-offline"
        default:
            asset = .checkoutOnline
            bundlePath = "Checkout/\(SnabbleUI.project.id)/checkout-online"
        }
        SnabbleUI.getAsset(asset, bundlePath: bundlePath) { img in
            self.icon.image = img
        }
    }

    // MARK: - polling timer
    private func startTimer() {
        self.processTimer?.invalidate()
        self.processTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            let project = SnabbleUI.project
            self.checkoutProcess.update(project,
                                taskCreated: { self.sessionTask = $0 },
                                completion: { self.update($0) })
        }
    }

    private func stopTimer() {
        self.processTimer?.invalidate()

        self.sessionTask?.cancel()
        self.sessionTask = nil
    }

    // MARK: - process updates
    enum CheckResult {
        case continuePolling
        case rejectCheckout
        case finalizeCheckout
    }

    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        switch result.result {
        case .success(let process):
            checkoutProcess = process

            switch checkContinuation(for: process) {
            case .continuePolling:
                self.startTimer()
            case .rejectCheckout:
                showCheckoutRejected(process: process)
            case .finalizeCheckout:
                finalizeCheckout()
            }

        case .failure(let error):
            Log.error(String(describing: error))
        }
    }

    private func finalizeCheckout() {
        guard
            let method = checkoutProcess.rawPaymentMethod,
            let checkoutDisplay = method.checkoutDisplayViewController(shop: shop,
                                                                       checkoutProcess: checkoutProcess,
                                                                       shoppingCart: shoppingCart,
                                                                       delegate: delegate)
        else {
            self.delegate?.showWarningMessage(L10n.Snabble.Payment.errorStarting)
            return
        }

        self.navigationController?.pushViewController(checkoutDisplay, animated: true)
    }

    private func showCheckoutRejected(process: CheckoutProcess) {
        let reject = SupervisorRejectedViewController(process)
        self.shoppingCart.generateNewUUID()
        reject.delegate = self.delegate
        self.navigationController?.pushViewController(reject, animated: true)
    }

    @objc private func cancelPayment() {
        self.delegate?.track(.paymentCancelled)

        self.stopTimer()

        self.checkoutProcess.abort(SnabbleUI.project) { result in
            switch result {
            case .success:
                self.shoppingCart.generateNewUUID()
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
                    self.startTimer()
                })
                self.present(alert, animated: true)
            }
        }
    }
}
