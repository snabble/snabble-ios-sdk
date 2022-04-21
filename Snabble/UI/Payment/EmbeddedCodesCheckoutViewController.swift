//
//  EmbeddedCodesCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import DeviceKit

final class EmbeddedCodesCheckoutViewController: UIViewController {
    private weak var stackViewLayout: UILayoutGuide?
    private weak var topWrapper: UIView?
    private weak var topIcon: UIImageView?
    private weak var arrowWrapper: UIView?
    private weak var idLabel: UILabel?
    private weak var messageLabel: UILabel?
    private weak var codeCountLabel: UILabel?
    private weak var scrollView: UIScrollView?
    private weak var paidButton: UIButton?
    private weak var pageControl: UIPageControl?

    private var initialBrightness: CGFloat = 0
    private var scrollViewWidth: CGFloat = 0

    private let cart: ShoppingCart
    private let shop: Shop
    weak var delegate: PaymentDelegate?
    private let process: CheckoutProcess?
    private var qrCodeConfig: QRCodeConfig

    private var codes = [String]()

    private var customLabel: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .label
        label.textAlignment = .natural
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        return label
    }

    private var iconImage: UIImageView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow + 2, for: .vertical)
        return imageView
    }

    public init(shop: Shop,
                checkoutProcess: CheckoutProcess?,
                cart: ShoppingCart,
                qrCodeConfig: QRCodeConfig) {
        self.process = checkoutProcess
        self.cart = cart
        self.shop = shop
        self.qrCodeConfig = qrCodeConfig

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        let contentView = UIView(frame: UIScreen.main.bounds)
        contentView.backgroundColor = .systemBackground

        let paidButton = UIButton(type: .system)
        paidButton.translatesAutoresizingMaskIntoConstraints = false
        paidButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        paidButton.makeSnabbleButton()
        paidButton.setTitle(L10n.Snabble.QRCode.didPay, for: .normal)
        paidButton.alpha = 0
        paidButton.isUserInteractionEnabled = false
        paidButton.addTarget(self, action: #selector(paidButtonTapped(_:)), for: .touchUpInside)

        let stackViewLayout = UILayoutGuide()

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 0

        let topWrapper = UIView()
        topWrapper.translatesAutoresizingMaskIntoConstraints = false

        let topIcon = iconImage

        let messageLabel = customLabel

        let arrowWrapper = UIView()
        arrowWrapper.translatesAutoresizingMaskIntoConstraints = false

        let arrowIcon = iconImage
        arrowIcon.image = Asset.SnabbleSDK.arrowUp.image

        let codeCountLabel = customLabel

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false

        let idLabel = customLabel
        idLabel.font = UIFont.systemFont(ofSize: 13)

        let codeContainer = UIView()
        codeContainer.translatesAutoresizingMaskIntoConstraints = true

        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.pageIndicatorTintColor = .systemGray6
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.addTarget(self, action: #selector(self.pageControlTapped(_:)), for: UIControl.Event.valueChanged)

        contentView.addLayoutGuide(stackViewLayout)
        contentView.addSubview(stackView)
        contentView.addSubview(paidButton)

        stackView.addArrangedSubview(topWrapper)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(arrowWrapper)
        stackView.addArrangedSubview(codeCountLabel)
        stackView.addArrangedSubview(codeContainer)
        stackView.addArrangedSubview(idLabel)
        stackView.addArrangedSubview(pageControl)

        topWrapper.addSubview(topIcon)
        arrowWrapper.addSubview(arrowIcon)
        codeContainer.addSubview(scrollView)

        NSLayoutConstraint.activate([
            paidButton.heightAnchor.constraint(equalToConstant: 48),
            paidButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            paidButton.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            paidButton.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            stackViewLayout.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            stackViewLayout.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackViewLayout.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackViewLayout.bottomAnchor.constraint(equalTo: paidButton.topAnchor),

            stackView.leadingAnchor.constraint(equalTo: stackViewLayout.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: stackViewLayout.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: stackViewLayout.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: stackViewLayout.topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: stackViewLayout.bottomAnchor),

            topIcon.centerXAnchor.constraint(equalTo: topWrapper.centerXAnchor),
            topIcon.centerYAnchor.constraint(equalTo: topWrapper.centerYAnchor),
            topIcon.topAnchor.constraint(equalTo: topWrapper.topAnchor, constant: 16),
            topIcon.bottomAnchor.constraint(equalTo: topWrapper.bottomAnchor, constant: -16),

            messageLabel.heightAnchor.constraint(equalToConstant: 25),

            arrowWrapper.heightAnchor.constraint(equalToConstant: 30),
            arrowIcon.leadingAnchor.constraint(equalTo: arrowWrapper.leadingAnchor),
            arrowIcon.trailingAnchor.constraint(equalTo: arrowWrapper.trailingAnchor),
            arrowIcon.topAnchor.constraint(equalTo: arrowWrapper.topAnchor),
            arrowIcon.bottomAnchor.constraint(equalTo: arrowWrapper.bottomAnchor),

            codeCountLabel.heightAnchor.constraint(equalToConstant: 25),
            scrollView.leadingAnchor.constraint(equalTo: codeContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: codeContainer.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: codeContainer.topAnchor, constant: 16),
            scrollView.bottomAnchor.constraint(equalTo: codeContainer.bottomAnchor, constant: -16),

            idLabel.heightAnchor.constraint(equalToConstant: 21),
            pageControl.heightAnchor.constraint(equalToConstant: 37)
        ])

        self.view = contentView
        self.stackViewLayout = stackViewLayout
        self.topWrapper = topWrapper
        self.topIcon = topIcon
        self.messageLabel = messageLabel
        self.arrowWrapper = arrowWrapper
        self.codeCountLabel = codeCountLabel
        self.scrollView = scrollView
        self.idLabel = idLabel
        self.pageControl = pageControl
        self.paidButton = paidButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = L10n.Snabble.QRCode.title

        if Snabble.isInFlightCheckoutPending {
            self.navigationItem.hidesBackButton = true
        }

        self.topWrapper?.isHidden = true
        self.arrowWrapper?.isHidden = true
        setupIcon()

        let msg = L10n.Snabble.QRCode.message
        self.messageLabel?.text = msg
        self.messageLabel?.isHidden = msg.isEmpty

        let generator = QRCodeGenerator(cart: cart, config: self.qrCodeConfig, processId: process?.id)
        self.codes = generator.generateCodes()
        self.codeCountLabel?.isHidden = self.codes.count == 1
        self.pageControl?.numberOfPages = self.codes.count
        self.pageControl?.pageIndicatorTintColor = .lightGray
        self.pageControl?.currentPageIndicatorTintColor = .label
        self.pageControl?.isHidden = self.codes.count == 1

        let id = process?.links._self.href.suffix(4) ?? "offline"
        self.idLabel?.text = String(id)

        self.setButtonTitle(for: pageControl?.currentPage ?? 0)
        self.configureViewForDevice()

        self.scrollView?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.delegate?.track(.viewEmbeddedCodesCheckout)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate?.track(.brightnessIncreased)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let scrollView = self.scrollView else { return }

        let maxCodeSize = self.maxCodeSize(fitting: self.scrollViewWidth)
        scrollView.widthAnchor.constraint(equalToConstant: maxCodeSize).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: maxCodeSize).isActive = true

        scrollView.contentSize = CGSize(width: maxCodeSize * CGFloat(self.codes.count), height: scrollView.frame.height)
        for x in 0..<self.codes.count {
            let page = UIImageView()
            page.translatesAutoresizingMaskIntoConstraints = false
            page.contentMode = .scaleAspectFit
            page.image = qrCode(with: self.codes[x], fitting: maxCodeSize)
            scrollView.addSubview(page)

            page.widthAnchor.constraint(equalToConstant: maxCodeSize).isActive = true
            page.heightAnchor.constraint(equalToConstant: maxCodeSize).isActive = true
            page.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(x) * maxCodeSize).isActive = true
            page.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.2) {
                self.paidButton?.alpha = 1
            }
            self.paidButton?.isUserInteractionEnabled = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness

        if self.isMovingFromParent {
            // user "aborted" this payment process by tapping 'Back'
            self.cart.generateNewUUID()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupIcon()
    }

    private func configureViewForDevice() {
        let smallDevices: [Device] = [
            .iPhone5s, .iPhoneSE, .iPodTouch6, .iPodTouch7
        ]
        let mediumDevices: [Device] = [
            .iPhone6, .iPhone6s, .iPhone7, .iPhone8, .iPhoneSE2, .iPhone12Mini, .iPhone13Mini
        ]

        let smallSimulators = smallDevices.map { Device.simulator($0) }
        let mediumSimulators = mediumDevices.map { Device.simulator($0) }

        let device = Device.current
        let multiplier: CGFloat
        if device.isOneOf(smallDevices) || device.isOneOf(smallSimulators) {
            // hide project graphic + arrow
            self.topWrapper?.isHidden = true
            self.arrowWrapper?.isHidden = true
            multiplier = 0.8
        } else if device.isOneOf(mediumDevices) || device.isOneOf(mediumSimulators) {
            // hide arrow, project graphic will likely scale
            self.arrowWrapper?.isHidden = true
            multiplier = 0.7
        } else {
            // all other devices: scale project graphic if needed
            multiplier = 0.6
        }

        self.scrollViewWidth = (self.stackViewLayout?.layoutFrame.width)! * multiplier
    }

    private func setButtonTitle(for page: Int) {
        let title: String
        if page == codes.count - 1 {
            title = L10n.Snabble.QRCode.didPay
        } else {
            title = L10n.Snabble.QRCode.nextCode(page + 2, codes.count)
        }
        paidButton?.setTitle(title, for: .normal)

        let codeXofY = L10n.Snabble.QRCode.codeXofY(page + 1, codes.count)
        codeCountLabel?.text = codeXofY
    }

    @objc private func paidButtonTapped(_ sender: Any) {
        if self.pageControl?.currentPage != self.codes.count - 1 {
            self.pageControl?.currentPage += 1
            guard let page = pageControl?.currentPage else {return}//
            self.updatePageControl(with: page)
            self.setButtonTitle(for: page)
        } else {
            self.delegate?.track(.markEmbeddedCodesPaid)
            self.cart.removeAll(endSession: true, keepBackup: true)
            Snabble.clearInFlightCheckout()

            let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: cart, checkoutProcess: process)
            checkoutSteps.paymentDelegate = delegate
            self.navigationController?.pushViewController(checkoutSteps, animated: true)
        }
    }

    private func setupIcon() {
        SnabbleUI.getAsset(.checkoutOffline, bundlePath: "Checkout/\(SnabbleUI.project.id)/checkout-offline") { img in
            if let img = img {
                self.topIcon?.image = img
                self.topIcon?.heightAnchor.constraint(equalToConstant: img.size.height).usingPriority(.required - 1).isActive = true
                self.topWrapper?.isHidden = false
                self.arrowWrapper?.isHidden = false
            }
        }
    }

    @objc private func pageControlTapped(_ pageControl: UIPageControl) {
        updatePageControl(with: pageControl.currentPage)
        setButtonTitle(for: pageControl.currentPage)
    }

    private func updatePageControl(with page: Int) {
        if page < codes.count {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) {
                    self.scrollView?.contentOffset = CGPoint(x: CGFloat(page) * (self.scrollView?.frame.width)!, y: 0)
                }
            }
        }
    }
}

extension EmbeddedCodesCheckoutViewController {
    private func maxCodeSize(fitting width: CGFloat) -> CGFloat {
        var maxWidth: CGFloat = 0
        for code in self.codes {
            if let img = self.qrCode(with: code, fitting: width) {
                maxWidth = max(maxWidth, img.size.width)
            }
        }
        return maxWidth
    }

    private func qrCode(with code: String, fitting width: CGFloat) -> UIImage? {
        for scale in (1...7).reversed() {
            if let img = QRCode.generate(for: code, scale: scale) {
                if img.size.width <= width {
                    return img
                }
            }
        }
        return nil
    }
}

extension EmbeddedCodesCheckoutViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl?.currentPage = scrollView.currentPage
        setButtonTitle(for: scrollView.currentPage)
    }
}
