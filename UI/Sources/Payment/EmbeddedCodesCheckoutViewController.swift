//
//  EmbeddedCodesCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import DeviceKit
import SnabbleCore
import SnabbleAssetProviding

final class EmbeddedCodesCheckoutViewController: UIViewController {
    private weak var scrollView: UIScrollView?
    private weak var stackViewLayout: UILayoutGuide?
    private weak var topWrapper: UIView?
    private weak var topIcon: UIImageView?
    private weak var arrowWrapper: UIView?
    private weak var idLabel: UILabel?
    private weak var messageLabel: UILabel?
    private weak var codeCountLabel: UILabel?
    private weak var codeScrollView: UIScrollView?
    private weak var paidButton: UIButton?
    private weak var pageControl: UIPageControl?

    private var initialBrightness: CGFloat = 0
    private var maxScrollViewWidth: CGFloat = 0
    private var maxPageSize: CGFloat = 0
    private let arrowIconHeight: CGFloat = 30

    private let cart: ShoppingCart
    private let shop: Shop
    weak var delegate: PaymentDelegate?
    private let process: CheckoutProcess?
    private var qrCodeConfig: QRCodeConfig

    private var codes = [String]()
    private var codeImages = [UIImage]()

    private var customLabel: UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.textAlignment = .natural
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
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
        if #available(iOS 15, *) {
            contentView.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        contentView.addSubview(scrollView)
        self.scrollView = scrollView

        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide

        let wrapperView = UIView()
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(wrapperView)

        let paidButton = UIButton(type: .system)
        paidButton.translatesAutoresizingMaskIntoConstraints = false
        paidButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        paidButton.titleLabel?.adjustsFontForContentSizeCategory = true
        paidButton.makeSnabbleButton()
        paidButton.titleLabel?.textAlignment = .center
        paidButton.setTitle(Asset.localizedString(forKey: "Snabble.QRCode.didPay"), for: .normal)
        paidButton.alpha = 0
        paidButton.isUserInteractionEnabled = false
        paidButton.addTarget(self, action: #selector(paidButtonTapped(_:)), for: .touchUpInside)

        let stackViewLayout = UILayoutGuide()
        wrapperView.addLayoutGuide(stackViewLayout)

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
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textAlignment = .center

        let arrowWrapper = UIView()
        arrowWrapper.translatesAutoresizingMaskIntoConstraints = false

        let arrowIcon = iconImage
        arrowIcon.image = Asset.image(named: "SnabbleSDK/arrow-up")
        arrowIcon.adjustsImageSizeForAccessibilityContentSizeCategory = true

        let codeCountLabel = customLabel
        codeCountLabel.font = .preferredFont(forTextStyle: .headline)

        let codeScrollView = UIScrollView()
        codeScrollView.translatesAutoresizingMaskIntoConstraints = false
        codeScrollView.isPagingEnabled = true
        codeScrollView.showsHorizontalScrollIndicator = false
        codeScrollView.bounces = false

        let idLabel = customLabel
        idLabel.font = .preferredFont(forTextStyle: .footnote)

        let codeContainer = UIView()
        codeContainer.translatesAutoresizingMaskIntoConstraints = true

        let pageControl = UIPageControl()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.pageIndicatorTintColor = .systemGray6
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: UIControl.Event.valueChanged)

        wrapperView.addLayoutGuide(stackViewLayout)
        wrapperView.addSubview(stackView)
        wrapperView.addSubview(paidButton)

        stackView.addArrangedSubview(topWrapper)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(arrowWrapper)
        stackView.addArrangedSubview(codeCountLabel)
        stackView.addArrangedSubview(codeContainer)
        stackView.addArrangedSubview(idLabel)
        stackView.addArrangedSubview(pageControl)

        topWrapper.addSubview(topIcon)
        arrowWrapper.addSubview(arrowIcon)
        codeContainer.addSubview(codeScrollView)

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

            paidButton.heightAnchor.constraint(equalToConstant: 48),
            paidButton.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -16),
            paidButton.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            paidButton.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),

            stackViewLayout.topAnchor.constraint(equalTo: wrapperView.topAnchor),
            stackViewLayout.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 16),
            stackViewLayout.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor, constant: -16),
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

            arrowIcon.leadingAnchor.constraint(equalTo: arrowWrapper.leadingAnchor),
            arrowIcon.trailingAnchor.constraint(equalTo: arrowWrapper.trailingAnchor),
            arrowIcon.topAnchor.constraint(equalTo: arrowWrapper.topAnchor),
            arrowIcon.bottomAnchor.constraint(equalTo: arrowWrapper.bottomAnchor),

            codeScrollView.leadingAnchor.constraint(equalTo: codeContainer.leadingAnchor),
            codeScrollView.trailingAnchor.constraint(equalTo: codeContainer.trailingAnchor),
            codeScrollView.topAnchor.constraint(equalTo: codeContainer.topAnchor, constant: 16),
            codeScrollView.bottomAnchor.constraint(equalTo: codeContainer.bottomAnchor, constant: -16),

            pageControl.heightAnchor.constraint(equalToConstant: 37)
        ])

        self.view = contentView
        self.stackViewLayout = stackViewLayout
        self.topWrapper = topWrapper
        self.topIcon = topIcon
        self.messageLabel = messageLabel
        self.arrowWrapper = arrowWrapper
        self.codeCountLabel = codeCountLabel
        self.codeScrollView = codeScrollView
        self.idLabel = idLabel
        self.pageControl = pageControl
        self.paidButton = paidButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Asset.localizedString(forKey: "Snabble.QRCode.title")

        if Snabble.isInFlightCheckoutPending {
            navigationItem.hidesBackButton = true
        }

        topWrapper?.isHidden = true
        arrowWrapper?.isHidden = true
        setupIcon()

        let msg = Asset.localizedString(forKey: "Snabble.QRCode.message")
        messageLabel?.text = msg
        messageLabel?.isHidden = msg.isEmpty

        let generator = QRCodeGenerator(cart: cart, config: qrCodeConfig, processId: process?.id)
        codes = generator.generateCodes()
        codeCountLabel?.isHidden = codes.count == 1
        pageControl?.numberOfPages = codes.count
        pageControl?.pageIndicatorTintColor = .lightGray
        pageControl?.currentPageIndicatorTintColor = .label
        pageControl?.isHidden = codes.count == 1

        let id = process?.links._self.href.suffix(4) ?? "offline"
        idLabel?.text = String(id)
        setButtonTitle(for: pageControl?.currentPage ?? 0)
        configureViewForDevice()
        configureCodeScrollView()

        codeScrollView?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        delegate?.track(.viewEmbeddedCodesCheckout)

        initialBrightness = UIScreen.main.brightness
        if initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            delegate?.track(.brightnessIncreased)
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

        UIScreen.main.brightness = initialBrightness

        if isMovingFromParent {
            // user "aborted" this payment process by tapping 'Back'
            cart.generateNewUUID()
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
            topWrapper?.isHidden = true
            arrowWrapper?.isHidden = true
            multiplier = 0.8
        } else if device.isOneOf(mediumDevices) || device.isOneOf(mediumSimulators) {
            // hide arrow, project graphic will likely scale
            arrowWrapper?.isHidden = true
            multiplier = 0.7
        } else {
            // all other devices: scale project graphic if needed
            multiplier = 0.6
        }
        maxScrollViewWidth = self.view.frame.width * multiplier
    }

    private func configureCodeScrollView() {
        guard let scrollView = codeScrollView else { return }

        for x in 0..<codes.count {
            if let image = qrCode(with: codes[x], fitting: maxScrollViewWidth) {
                codeImages.append(image)
            }
        }
        maxPageSize = maxCodeSize(for: codeImages)

        scrollView.widthAnchor.constraint(equalToConstant: maxPageSize).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: maxPageSize).isActive = true
        scrollView.contentSize = CGSize(width: maxPageSize * CGFloat(codeImages.count), height: scrollView.frame.height)

        for x in 0..<codeImages.count {
            let page = UIImageView()
            page.translatesAutoresizingMaskIntoConstraints = false
            page.contentMode = .scaleAspectFit
            page.image = codeImages[x]
            scrollView.addSubview(page)

            page.widthAnchor.constraint(equalToConstant: maxPageSize).isActive = true
            page.heightAnchor.constraint(equalToConstant: maxPageSize).isActive = true
            page.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: CGFloat(x) * maxPageSize).isActive = true
            page.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        }
    }

    private func setButtonTitle(for page: Int) {
        let title: String
        if page == codes.count - 1 {
            title = Asset.localizedString(forKey: "Snabble.QRCode.didPay")
        } else {
            title = Asset.localizedString(forKey: "Snabble.QRCode.nextCode", arguments: page + 2, codes.count)
        }
        paidButton?.setTitle(title, for: .normal)

        let codeXofY = Asset.localizedString(forKey: "Snabble.QRCode.codeXofY", arguments: page + 1, codes.count)
        codeCountLabel?.text = codeXofY
    }

    @objc private func paidButtonTapped(_ sender: Any) {
        if pageControl?.currentPage != codes.count - 1 {
            pageControl?.currentPage += 1
            guard let page = pageControl?.currentPage else {return}//
            updatePageControl(with: page)
            setButtonTitle(for: page)
        } else {
            delegate?.track(.markEmbeddedCodesPaid)
            cart.removeAll(endSession: true, keepBackup: true)
            Snabble.clearInFlightCheckout()

            let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: cart, checkoutProcess: process)
            checkoutSteps.paymentDelegate = delegate
            navigationController?.pushViewController(checkoutSteps, animated: true)
        }
    }

    private func setupIcon() {
        SnabbleCI.getAsset(.checkoutOffline, bundlePath: "Checkout/\(SnabbleCI.project.id)/checkout-offline") { img in
            if let img = img {
                self.topIcon?.image = img
                self.topIcon?.heightAnchor.constraint(equalToConstant: img.size.height).usingPriority(.required - 1).isActive = true
                self.topWrapper?.isHidden = false
                let scaledArrowWrapperHeight = UIFontMetrics.default.scaledValue(for: self.arrowIconHeight)
                self.arrowWrapper?.heightAnchor.constraint(equalToConstant: scaledArrowWrapperHeight).usingPriority(.defaultHigh + 1).isActive = true
                self.arrowWrapper?.isHidden = false
            }
        }
    }

    @objc private func pageControlTapped(_ pageControl: UIPageControl) {
        updatePageControl(with: pageControl.currentPage)
        setButtonTitle(for: pageControl.currentPage)
    }

    private func updatePageControl(with page: Int) {
        guard let scrollView = codeScrollView else { return }
        if page < codes.count {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) {
                    scrollView.contentOffset = CGPoint(x: CGFloat(page) * scrollView.frame.width, y: 0)
                }
            }
        }
    }
}

extension EmbeddedCodesCheckoutViewController {
    private func maxCodeSize(for images: [UIImage]) -> CGFloat {
        var maxWidth: CGFloat = 0
        for image in codeImages {
            maxWidth = max(maxWidth, image.size.width)
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
        return QRCode.generate(for: code, scale: 1)
    }
}

extension EmbeddedCodesCheckoutViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl?.currentPage = scrollView.currentPage
        setButtonTitle(for: scrollView.currentPage)
    }
}
