//
//  BaseCheckViewController.swift
//
//  Copyright © 2022 snabble. All rights reserved.
//

import UIKit
import SnabbleCore

// base class for SupervisorCheckViewController and GatekeeperCheckViewController

protocol CheckModelDelegate: AnyObject {
    func checkContinuation(for process: CheckoutProcess) -> CheckModel.CheckResult
    func checkoutRejected(process: CheckoutProcess)
    func checkoutFinalized(process: CheckoutProcess)
    func checkoutAborted(process: CheckoutProcess)
}

open class CheckModel: CheckModelDelegate {
    
    private(set) var checkoutProcess: CheckoutProcess
    let shoppingCart: ShoppingCart
    let shop: Shop

    private weak var processTimer: Timer?
    private var sessionTask: URLSessionTask?
    
    weak var paymentDelegate: PaymentDelegate?
    weak var delegate: CheckModelDelegate?
    
    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        self.shop = shop
        self.shoppingCart = shoppingCart
        self.checkoutProcess = checkoutProcess
    }
    
    // MARK: - polling timer
    func startTimer() {
        self.processTimer?.invalidate()
        self.processTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            let project = SnabbleCI.project
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
    
    private func update(_ result: RawResult<CheckoutProcess, SnabbleError>) {
        switch result.result {
        case .success(let process):
            checkoutProcess = process

            switch checkContinuation(for: process) {
            case .continuePolling:
                self.startTimer()
            case .rejectCheckout:
                self.checkoutRejected(process: process)
            case .finalizeCheckout:
                self.checkoutFinalized(process: process)
            }

        case .failure(let error):
            Log.error(String(describing: error))
        }
    }
    
    // MARK: - process updates
    enum CheckResult {
        case continuePolling
        case rejectCheckout
        case finalizeCheckout
    }

    func checkContinuation(for process: CheckoutProcess) -> CheckResult {
        guard let delegate = delegate else {
            fatalError("delegate must be set")
        }
        return delegate.checkContinuation(for: process)
    }
    
    func checkoutRejected(process: SnabbleCore.CheckoutProcess) {
        delegate?.checkoutRejected(process: process)
    }
    
    func checkoutFinalized(process: SnabbleCore.CheckoutProcess) {
        delegate?.checkoutFinalized(process: process)
    }
    
    func checkoutAborted(process: SnabbleCore.CheckoutProcess) {
        Snabble.clearInFlightCheckout()
        self.shoppingCart.generateNewUUID()
        delegate?.checkoutAborted(process: process)
    }

    @objc func cancelPayment() {
        self.paymentDelegate?.track(.paymentCancelled)
        self.stopTimer()

        self.checkoutProcess.abort(SnabbleCI.project) { result in
            switch result {
            case .success(let process):
                self.checkoutAborted(process: process)
            case .failure:
                let alertView = AlertView(title: Asset.localizedString(forKey: "Snabble.Payment.CancelError.title"),
                                          message: Asset.localizedString(forKey: "Snabble.Payment.CancelError.message"))
                alertView.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default) { _ in
                    self.startTimer()
                })
                alertView.show()
            }
        }
    }
}

class BaseCheckViewController: UIViewController, CheckModelDelegate {
    
    private var checkoutProcess: CheckoutProcess {
        self.checkModel.checkoutProcess
    }

    weak var stackView: UIStackView?
    weak var iconWrapper: UIView?
    weak var textWrapper: UIView?
    weak var arrowWrapper: UIView?
    weak var codeWrapper: UIView?
    weak var idWrapper: UIView?

    private weak var icon: UIImageView?
    weak var text: UILabel?
    private weak var code: UIImageView?
    private weak var id: UILabel?

    private weak var cancelButton: UIButton?

    private var initialBrightness: CGFloat = 0
    private let arrowIconHeight: CGFloat = 30

    weak var delegate: PaymentDelegate? {
        didSet {
            self.checkModel.paymentDelegate = delegate
        }
    }
    
    let checkModel: CheckModel
    
    init(shop: Shop, shoppingCart: ShoppingCart, checkoutProcess: CheckoutProcess) {
        let model = CheckModel(shop: shop, shoppingCart: shoppingCart, checkoutProcess: checkoutProcess)
        self.checkModel = model
        
        super.init(nibName: nil, bundle: nil)

        self.checkModel.delegate = self
        self.hidesBottomBarWhenPushed = true

        title = Asset.localizedString(forKey: "Snabble.Payment.confirm")
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
        cancelButton.setTitle(Asset.localizedString(forKey: "Snabble.cancel"), for: .normal)
        cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
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
        text.textColor = .label
        text.textAlignment = .center
        text.numberOfLines = 0
        text.font = .preferredFont(forTextStyle: .body)
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
        let arrow = UIImageView(image: Asset.image(named: "SnabbleSDK/arrow-up"))
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
        id.textColor = .label
        id.textAlignment = .center
        id.font = .preferredFont(forTextStyle: .footnote)
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
        self.text?.text = Asset.localizedString(forKey: "Snabble.Payment.Online.message")

        self.id?.text = String(checkModel.checkoutProcess.id.suffix(4))

        checkModel.startTimer()
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

    func checkContinuation(for process: CheckoutProcess) -> CheckModel.CheckResult {
        fatalError("clients must override")
    }
    
    func checkoutRejected(process: SnabbleCore.CheckoutProcess) {
        let reject = SupervisorRejectedViewController(process)
        self.checkModel.shoppingCart.generateNewUUID()
        reject.delegate = self.delegate
        self.navigationController?.pushViewController(reject, animated: true)
    }
    
    func checkoutFinalized(process: SnabbleCore.CheckoutProcess) {
        guard
            let method = process.rawPaymentMethod,
            let checkoutDisplay = method.checkoutDisplayViewController(shop: self.checkModel.shop,
                                                                       checkoutProcess: process,
                                                                       shoppingCart: self.checkModel.shoppingCart,
                                                                       delegate: delegate)
        else {
            self.delegate?.showWarningMessage(Asset.localizedString(forKey: "Snabble.Payment.errorStarting"))
            return
        }

        self.navigationController?.pushViewController(checkoutDisplay, animated: true)
    }
    
    func checkoutAborted(process: SnabbleCore.CheckoutProcess) {
        if let cartVC = self.navigationController?.viewControllers.first(where: { $0 is ShoppingCartViewController}) {
            self.navigationController?.popToViewController(cartVC, animated: true)
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
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
            bundlePath = "Checkout/\(SnabbleCI.project.id)/checkout-offline"
        default:
            asset = .checkoutOnline
            bundlePath = "Checkout/\(SnabbleCI.project.id)/checkout-online"
        }
        SnabbleCI.getAsset(asset, bundlePath: bundlePath) { img in
            self.icon?.image = img
        }

        let scaledArrowWrapperHeight = UIFontMetrics.default.scaledValue(for: self.arrowIconHeight)
        self.arrowWrapper?.heightAnchor.constraint(equalToConstant: scaledArrowWrapperHeight).usingPriority(.defaultHigh + 1).isActive = true
    }

    @objc private func cancelPayment() {
        self.checkModel.cancelPayment()
    }
}
