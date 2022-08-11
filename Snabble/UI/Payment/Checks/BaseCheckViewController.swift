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

    weak var stackView: UIStackView?
    weak var iconWrapper: UIView?
    weak var textWrapper: UIView?
    weak var arrowWrapper: UIView?
    weak var codeWrapper: UIView?
    weak var idWrapper: UIView?

    private weak var icon: UIImageView?
    private weak var text: UILabel?
    private weak var code: UIImageView?
    private weak var id: UILabel?

    private weak var cancelButton: UIButton?

    private var initialBrightness: CGFloat = 0
    private let arrowIconHeight: CGFloat = 30

    weak var delegate: PaymentDelegate?

    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        self.shop = shop
        self.shoppingCart = shoppingCart
        self.checkoutProcess = checkoutProcess

        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true

        title = L10n.Snabble.Payment.confirm
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        // set the main view components
        let contentView = UIView(frame: UIScreen.main.bounds)
        contentView.backgroundColor = .systemBackground
        if #available(iOS 15, *) {
            contentView.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false

        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide

        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.makeSnabbleButton()
        cancelButton.titleLabel?.textAlignment = .center
        cancelButton.setTitle(L10n.Snabble.cancel, for: .normal)
        cancelButton.preferredFont(forTextStyle: .headline)
        cancelButton.alpha = 0
        cancelButton.isUserInteractionEnabled = false
        cancelButton.addTarget(self, action: #selector(self.cancelPayment), for: .touchUpInside)

        let stackViewLayout = UILayoutGuide()

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 0

        contentView.addSubview(scrollView)
        scrollView.addSubview(wrapperView)

        wrapperView.addLayoutGuide(stackViewLayout)
        wrapperView.addSubview(stackView)
        wrapperView.addSubview(cancelButton)

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

            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -16),
            cancelButton.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),

            stackViewLayout.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            stackViewLayout.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            stackViewLayout.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),
            stackViewLayout.bottomAnchor.constraint(equalTo: cancelButton.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: stackViewLayout.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackViewLayout.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackViewLayout.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackViewLayout.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackViewLayout.bottomAnchor)
        ])

        self.view = contentView
        self.stackView = stackView
        self.cancelButton = cancelButton

        // build the stackview components
        let iconWrapper = UIView()
        iconWrapper.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        icon.setContentHuggingPriority(.defaultLow + 2, for: .vertical)
        iconWrapper.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconWrapper.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconWrapper.centerYAnchor),
            icon.topAnchor.constraint(equalTo: iconWrapper.topAnchor, constant: 16),
            icon.bottomAnchor.constraint(equalTo: iconWrapper.bottomAnchor, constant: -16)
        ])
        self.iconWrapper = iconWrapper
        self.icon = icon

        let textWrapper = UIView()
        textWrapper.translatesAutoresizingMaskIntoConstraints = false
        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.textColor = Assets.Color.label()
        text.textAlignment = .center
        text.numberOfLines = 0
        text.font = UIFont.preferredFont(forTextStyle: .body)
        text.adjustsFontForContentSizeCategory = true
        textWrapper.addSubview(text)
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: textWrapper.leadingAnchor),
            text.trailingAnchor.constraint(equalTo: textWrapper.trailingAnchor),
            text.topAnchor.constraint(equalTo: textWrapper.topAnchor, constant: 4),
            text.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor, constant: -4)
        ])
        self.textWrapper = textWrapper
        self.text = text

        let arrowWrapper = UIView()
        arrowWrapper.translatesAutoresizingMaskIntoConstraints = false
        let arrow = UIImageView(image: Asset.SnabbleSDK.arrowUp.image)
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.adjustsImageSizeForAccessibilityContentSizeCategory = true
        arrow.contentMode = .scaleAspectFit
        arrow.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        arrow.setContentHuggingPriority(.defaultLow + 2, for: .vertical)
        arrowWrapper.addSubview(arrow)
        NSLayoutConstraint.activate([
            arrow.leadingAnchor.constraint(equalTo: arrowWrapper.leadingAnchor),
            arrow.trailingAnchor.constraint(equalTo: arrowWrapper.trailingAnchor),
            arrow.topAnchor.constraint(equalTo: arrowWrapper.topAnchor),
            arrow.bottomAnchor.constraint(equalTo: arrowWrapper.bottomAnchor)
        ])
        self.arrowWrapper = arrowWrapper

        let codeWrapper = UIView()
        codeWrapper.translatesAutoresizingMaskIntoConstraints = false
        let code = UIImageView()
        code.translatesAutoresizingMaskIntoConstraints = false
        code.contentMode = .scaleAspectFit
        code.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        code.setContentHuggingPriority(.defaultLow + 2, for: .vertical)
        codeWrapper.addSubview(code)
        NSLayoutConstraint.activate([
            code.leadingAnchor.constraint(equalTo: codeWrapper.leadingAnchor),
            code.trailingAnchor.constraint(equalTo: codeWrapper.trailingAnchor),
            code.topAnchor.constraint(equalTo: codeWrapper.topAnchor, constant: 16),
            code.bottomAnchor.constraint(equalTo: codeWrapper.bottomAnchor, constant: -16)
        ])
        self.codeWrapper = codeWrapper
        self.code = code

        let idWrapper = UIView()
        idWrapper.translatesAutoresizingMaskIntoConstraints = false
        let id = UILabel()
        id.translatesAutoresizingMaskIntoConstraints = false
        id.textColor = Assets.Color.label()
        id.textAlignment = .center
        id.font = UIFont.preferredFont(forTextStyle: .footnote)
        id.adjustsFontForContentSizeCategory = true
        idWrapper.addSubview(id)
        NSLayoutConstraint.activate([
            id.leadingAnchor.constraint(equalTo: idWrapper.leadingAnchor),
            id.trailingAnchor.constraint(equalTo: idWrapper.trailingAnchor),
            id.topAnchor.constraint(equalTo: idWrapper.topAnchor, constant: 4),
            id.bottomAnchor.constraint(equalTo: idWrapper.bottomAnchor, constant: -4)
        ])
        self.idWrapper = idWrapper
        self.id = id

        arrangeLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.hidesBackButton = true

        self.initialBrightness = UIScreen.main.brightness
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.2) {
                self.cancelButton?.alpha = 1
            }
            self.cancelButton?.isUserInteractionEnabled = true
        }

        UIApplication.shared.isIdleTimerDisabled = true

        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate?.track(.brightnessIncreased)
        }

        self.setIcons()

        let codeContent = codeContent()
        self.code?.image = renderCode(codeContent)

        let onlineMessageKey = "Snabble.Payment.Online.message"
        let onlineMessage = Snabble.l10n(onlineMessageKey)
        self.text?.text = onlineMessage
        // hide if there is no text/translation
        self.textWrapper?.isHidden = onlineMessage == onlineMessageKey.uppercased()

        self.id?.text = String(checkoutProcess.id.suffix(4))

        self.startTimer()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setIcons()
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

    private func setIcons() {
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
            self.icon?.image = img
        }

        let scaledArrowWrapperHeight = UIFontMetrics.default.scaledValue(for: self.arrowIconHeight)
        self.arrowWrapper?.heightAnchor.constraint(equalToConstant: scaledArrowWrapperHeight).usingPriority(.defaultHigh + 1).isActive = true
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
                Snabble.clearInFlightCheckout()
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
