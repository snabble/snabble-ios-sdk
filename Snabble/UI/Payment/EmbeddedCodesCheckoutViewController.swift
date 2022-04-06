//
//  EmbeddedCodesCheckoutViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import DeviceKit

final class EmbeddedCodesCheckoutViewController: UIViewController {
    @IBOutlet private var topWrapper: UIView!
    @IBOutlet private var topIcon: UIImageView!
    @IBOutlet private var iconHeight: NSLayoutConstraint!

    @IBOutlet private var arrowWrapper: UIView!

    @IBOutlet private var idWrapper: UIView!
    @IBOutlet private var idLabel: UILabel!

    @IBOutlet private var messageWrapper: UIView!
    @IBOutlet private var messageLabel: UILabel!

    @IBOutlet private var codeCountWrapper: UIView!
    @IBOutlet private var codeCountLabel: UILabel!

    @IBOutlet private var paidButton: UIButton!

    @IBOutlet private var pageControlWrapper: UIView!
    @IBOutlet private var pageControl: UIPageControl!

    @IBOutlet private var codeContainer: UIView!
    @IBOutlet private var codeContainerWidth: NSLayoutConstraint!

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var collectionViewWidth: NSLayoutConstraint!

    private var initialBrightness: CGFloat = 0

    private let cart: ShoppingCart
    private let shop: Shop
    weak var delegate: PaymentDelegate?
    private let process: CheckoutProcess?
    private var qrCodeConfig: QRCodeConfig

    private var codes = [String]()
    private var itemSize = CGSize.zero

    public init(shop: Shop,
                checkoutProcess: CheckoutProcess?,
                cart: ShoppingCart,
                qrCodeConfig: QRCodeConfig) {
        self.process = checkoutProcess
        self.cart = cart
        self.shop = shop
        self.qrCodeConfig = qrCodeConfig

        super.init(nibName: nil, bundle: SnabbleSDKBundle.main)

        self.title = L10n.Snabble.QRCode.title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.paidButton.makeSnabbleButton()
        self.paidButton.setTitle(L10n.Snabble.QRCode.didPay, for: .normal)
        self.paidButton.alpha = 0
        self.paidButton.isUserInteractionEnabled = false

        self.topWrapper.isHidden = true
        self.arrowWrapper.isHidden = true
        setupIcon()

        let msg = L10n.Snabble.QRCode.message
        self.messageLabel.text = msg
        self.messageWrapper.isHidden = msg.isEmpty

        let nib = UINib(nibName: "QRCodeCell", bundle: SnabbleSDKBundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "qrCodeCell")

        let generator = QRCodeGenerator(cart: cart, config: self.qrCodeConfig, processId: process?.id)
        self.codes = generator.generateCodes()

        self.codeCountWrapper.isHidden = self.codes.count == 1

        self.pageControl.numberOfPages = self.codes.count
        self.pageControl.pageIndicatorTintColor = .lightGray
        self.pageControl.currentPageIndicatorTintColor = .label
        self.pageControlWrapper.isHidden = self.codes.count == 1

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        let id = process?.links._self.href.suffix(4) ?? "offline"
        self.idLabel.text = String(id)

        self.setButtonTitle()
        self.configureViewForDevice()
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

        let frameWidth = self.codeContainer.frame.width
        let maxCodeSize = self.maxCodeSize(fitting: frameWidth)

        self.collectionViewWidth.constant = maxCodeSize

        if maxCodeSize != self.itemSize.width {
            self.itemSize = CGSize(width: maxCodeSize, height: maxCodeSize)
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.2) {
                self.paidButton.alpha = 1
            }
            self.paidButton.isUserInteractionEnabled = true
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

        self.codeContainerWidth.isActive = false

        let multiplier: CGFloat
        if device.isOneOf(smallDevices) || device.isOneOf(smallSimulators) {
            // hide project graphic + arrow
            self.topWrapper.isHidden = true
            self.arrowWrapper.isHidden = true
            multiplier = 0.8
        } else if device.isOneOf(mediumDevices) || device.isOneOf(mediumSimulators) {
            // hide arrow, project graphic will likely scale
            self.arrowWrapper.isHidden = true
            multiplier = 0.7
        } else {
            // all other devices: scale project graphic if needed
            multiplier = 0.6
        }

        NSLayoutConstraint.activate([
            self.codeContainer.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: multiplier, constant: 0)
        ])
    }

    private func setButtonTitle() {
        var title = ""
        if self.pageControl.currentPage == self.codes.count - 1 {
            title = L10n.Snabble.QRCode.didPay
        } else {
            title = L10n.Snabble.QRCode.nextCode(self.pageControl.currentPage + 2, self.codes.count)
        }
        self.paidButton.setTitle(title, for: .normal)

        let codeXofY = L10n.Snabble.QRCode.codeXofY(self.pageControl.currentPage + 1, self.codes.count)
        self.codeCountLabel.text = codeXofY
    }

    @IBAction private func paidButtonTapped(_ sender: UIButton) {
        if self.pageControl.currentPage != self.codes.count - 1 {
            self.pageControl.currentPage += 1
            let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)

            self.setButtonTitle()
        } else {
            self.delegate?.track(.markEmbeddedCodesPaid)
            self.cart.removeAll(endSession: true, keepBackup: true)

            let checkoutSteps = CheckoutStepsViewController(shop: shop, shoppingCart: cart, checkoutProcess: process)
            checkoutSteps.paymentDelegate = delegate
            self.navigationController?.pushViewController(checkoutSteps, animated: true)
        }
    }

    private func setupIcon() {
        SnabbleUI.getAsset(.checkoutOffline, bundlePath: "Checkout/\(SnabbleUI.project.id)/checkout-offline") { img in
            if let img = img {
                self.topIcon.image = img
                self.iconHeight.constant = img.size.height
                self.topWrapper.isHidden = false
                self.arrowWrapper.isHidden = false
            }
        }
    }
}

extension EmbeddedCodesCheckoutViewController {
    private func qrCode(with code: String) -> UIImage? {
        // Log.debug("QR Code content:\n\(code)")
        return self.qrCode(with: code, fitting: self.collectionView.frame.width)
    }

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

extension EmbeddedCodesCheckoutViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.codes.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "qrCodeCell", for: indexPath) as! QRCodeCell

        let img = self.qrCode(with: self.codes[indexPath.row])
        cell.setImage(img)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }

    @IBAction private func pageControlTapped(_ pageControl: UIPageControl) {
        if pageControl.currentPage < self.codes.count {
            let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        }
        self.setButtonTitle()
    }

    // adjust the page control when the scrolling ends
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let newPage = Int((scrollView.contentOffset.x + self.itemSize.width / 2) / self.itemSize.width)
        self.pageControl.currentPage = newPage
        self.setButtonTitle()
    }
}
