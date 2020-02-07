//
//  EmbeddedCodesCheckoutViewController.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import UIKit

final class EmbeddedCodesCheckoutViewController: UIViewController {

    @IBOutlet private weak var topWrapper: UIView!
    @IBOutlet private weak var topIcon: UIImageView!
    @IBOutlet private weak var iconHeight: NSLayoutConstraint!
    @IBOutlet private weak var arrowWrapper: UIView!
    @IBOutlet private weak var codeWrapper: UIView!

    @IBOutlet private weak var codeContainer: UIView!
    @IBOutlet private weak var idWrapper: UIView!
    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var pageControlWrapper: UIView!

    @IBOutlet private weak var paidButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!

    private var initialBrightness: CGFloat = 0

    private weak var cart: ShoppingCart!
    private weak var delegate: PaymentDelegate!
    private var process: CheckoutProcess?
    private var qrCodeConfig: QRCodeConfig

    private var codes = [String]()
    private var itemSize = CGSize.zero

    init(_ process: CheckoutProcess?, _ cart: ShoppingCart, _ delegate: PaymentDelegate, _ codeConfig: QRCodeConfig) {
        self.process = process
        self.cart = cart
        self.delegate = delegate

        self.qrCodeConfig = codeConfig

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.QRCode.title".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.paidButton.makeSnabbleButton()
        self.paidButton.setTitle("Snabble.QRCode.didPay".localized(), for: .normal)
        self.paidButton.alpha = 0
        self.paidButton.isUserInteractionEnabled = false

        if let icon = UIImage.fromBundle(self.iconName()) {
            self.topIcon.image = icon
            self.iconHeight.constant = icon.size.height
        } else {
            self.topWrapper.isHidden = true
            self.arrowWrapper.isHidden = true
        }

        let nib = UINib(nibName: "QRCodeCell", bundle: SnabbleBundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "qrCodeCell")

        let generator = QRCodeGenerator(self.cart, self.qrCodeConfig)
        self.codes = generator.generateCodes()

        self.pageControl.numberOfPages = self.codes.count
        self.pageControl.pageIndicatorTintColor = .lightGray
        self.pageControl.currentPageIndicatorTintColor = SnabbleUI.appearance.primaryColor
        self.pageControlWrapper.isHidden = self.codes.count == 1

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        let id = process?.links.`self`.href.suffix(4) ?? "offline"
        self.idLabel.text = String(id)

        self.setButtonTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.delegate.track(.viewEmbeddedCodesCheckout)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
            self.delegate.track(.brightnessIncreased)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let frameWidth = self.collectionView.frame.width
        let maxCodeSize = self.maxCodeSize(fitting: frameWidth)
        NSLayoutConstraint.activate([
            self.collectionView.heightAnchor.constraint(equalToConstant: maxCodeSize),
            self.collectionView.widthAnchor.constraint(equalToConstant: maxCodeSize)
        ])
        if maxCodeSize != self.itemSize.width {
            self.itemSize = CGSize(width: maxCodeSize, height: maxCodeSize)
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            UIView.animate(withDuration: 0.2) {
                self.paidButton.alpha = 1
            }
            self.paidButton.isUserInteractionEnabled = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness
    }

    private func iconName() -> String {
        let project = SnabbleUI.project.id
        return "Checkout/\(project)/checkout-offline"
    }

    private func setButtonTitle() {
        var title = ""
        if self.pageControl.currentPage == self.codes.count - 1 {
            title = "Snabble.QRCode.didPay".localized()
        } else {
            title = String(format: "Snabble.QRCode.nextCode".localized(),
                           self.pageControl.currentPage+2, self.codes.count)
        }
        self.paidButton.setTitle(title, for: .normal)
    }

    @IBAction func paidButtonTapped(_ sender: UIButton) {
        if self.pageControl.currentPage != self.codes.count - 1 {
            self.pageControl.currentPage += 1
            let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)

            self.setButtonTitle()
        } else {
            self.delegate.track(.markEmbeddedCodesPaid)
            self.cart.removeAll(endSession: true)
            NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)

            self.delegate.paymentFinished(true, self.cart, self.process)
        }
    }

}

extension EmbeddedCodesCheckoutViewController {
    private func qrCode(with code: String) -> UIImage? {
        Log.debug("QR Code content:\n\(code)")
        let start = Date.timeIntervalSinceReferenceDate
        defer {
            let elapsed = Date.timeIntervalSinceReferenceDate - start
            NSLog("code gen took \(elapsed)")
        }

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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.codes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "qrCodeCell", for: indexPath) as! QRCodeCell

        let img = self.qrCode(with: self.codes[indexPath.row])
        cell.imageView.image = img
        cell.imageWidth.constant = img?.size.width ?? 0

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }

    @IBAction func pageControlTapped(_ pageControl: UIPageControl) {
        if pageControl.currentPage < self.codes.count {
            let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: true)
        }
        self.setButtonTitle()
    }

    // adjust the page control when the scrolling ends
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let newPage = Int((scrollView.contentOffset.x + self.itemSize.width/2) / self.itemSize.width)
        self.pageControl.currentPage = newPage
        self.setButtonTitle()
    }
}
