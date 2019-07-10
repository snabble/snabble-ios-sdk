//
//  EmbeddedCodesCheckoutViewController.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import UIKit

final class EmbeddedCodesCheckoutViewController: UIViewController {

    @IBOutlet weak var explanation1: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var explanation2: UILabel!
    @IBOutlet weak var paidButton: UIButton!

    private var initialBrightness: CGFloat = 0

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    private weak var cart: ShoppingCart!
    private weak var delegate: PaymentDelegate!
    private var process: CheckoutProcess?
    private var method: PaymentMethod
    private var qrCodeConfig: QRCodeConfig

    private var codes = [String]()
    private var itemSize = CGSize(width: 100, height: 100)

    init(_ process: CheckoutProcess?, _ method: PaymentMethod, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.method = method
        self.cart = cart
        self.delegate = delegate
        self.qrCodeConfig = SnabbleUI.project.encodedCodes ?? QRCodeConfig.default

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.title = "Snabble.QRCode.title".localized()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.paidButton.backgroundColor = SnabbleUI.appearance.primaryColor
        self.paidButton.makeRoundedButton()
        self.paidButton.setTitle("Snabble.QRCode.didPay".localized(), for: .normal)
        self.paidButton.alpha = 0
        self.paidButton.isUserInteractionEnabled = false

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            UIView.animate(withDuration: 0.2) {
                self.paidButton.alpha = 1
            }
            self.paidButton.isUserInteractionEnabled = true
        }

        let nib = UINib(nibName: "QRCodeCell", bundle: SnabbleBundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "qrCodeCell")

        switch self.method {
        case .encodedCodes:
            let codeblocks = Codeblocks(self.qrCodeConfig)
            let (regularCodes, restrictedCodes) = self.codesForQR()
            self.codes = codeblocks.generateQrCodes(regularCodes, restrictedCodes)
        case .encodedCodesCSV:
            let codeblocks = CodeblocksCSV(self.qrCodeConfig)
            self.codes = codeblocks.generateQrCodes(self.cart)
        case .encodedCodesIKEA:
            let codeblocks = CodeblocksIKEA(self.qrCodeConfig)
            self.codes = codeblocks.generateQrCodes(self.cart, self.codesFor(self.cart.items))
        default:
            fatalError("payment method \(self.method) not implemented")
            break
        }

        self.pageControl.numberOfPages = self.codes.count
        self.pageControl.pageIndicatorTintColor = .lightGray
        self.pageControl.currentPageIndicatorTintColor = SnabbleUI.appearance.primaryColor
        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.setButtonTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.delegate.track(.viewEmbeddedCodesCheckout)

        self.initialBrightness = UIScreen.main.brightness
        if self.initialBrightness < 0.5 {
            UIScreen.main.brightness = 0.5
        }

        let formatter = PriceFormatter(SnabbleUI.project)

        // if we have a valid checkoutInfo, use the total from that, else what we've calculated in the cart
        let lineItems = self.process?.checkoutInfo.lineItems.count ?? 0
        let total = lineItems > 0 ? self.process?.checkoutInfo.price.price : self.cart.total

        let formattedTotal = formatter.format(total ?? 0)

        self.totalPriceLabel.text = "Snabble.QRCode.total".localized() + "\(formattedTotal)"

        let explKey = self.codes.count > 1 ? "Snabble.QRCode.showTheseCodes" : "Snabble.QRCode.showThisCode"
        let explanation = self.showCodesMessage(explKey)

        self.explanation1.text = String(format: explanation, self.codes.count)
        self.explanation2.text = "Snabble.QRCode.priceMayDiffer".localized()

        if total == nil {
            self.totalPriceLabel.isHidden = true
            self.explanation2.isHidden = true
        }
    }

    private func showCodesMessage(_ msgId: String) -> String {
        let projectId = SnabbleUI.project.id.replacingOccurrences(of: "-", with: ".")
        let textId = projectId + "." + msgId
        let l10n = NSLocalizedString(textId, comment: "")

        if l10n.hasPrefix(projectId) {
            return msgId.localized()
        } else {
            return l10n
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = self.collectionView.frame.width
        if width != self.itemSize.width {
            self.itemSize = CGSize(width: width, height: width)
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIScreen.main.brightness = self.initialBrightness
    }

    private func codesForQR() -> ([String],[String]) {
        let items = self.cart.items.sorted { $0.price < $1.price }

        if self.qrCodeConfig.nextCodeWithCheck != nil {
            let regularItems = items.filter { return $0.product.saleRestriction == .none }
            let restrictedItems = items.filter { return $0.product.saleRestriction != .none }

            var regularCodes = [String]()
            if let card = self.cart.customerCard {
                regularCodes.append(card)
            }
            regularCodes += self.codesFor(regularItems)

            let restrictedCodes = self.codesFor(restrictedItems)

            return (regularCodes, restrictedCodes)
        } else {
            var codes = [String]()
            if let card = self.cart.customerCard {
                codes.append(card)
            }
            codes += self.codesFor(items)

            return (codes, [])
        }
    }

    private func codesFor(_ items: [CartItem]) -> [String] {
        return items.reduce(into: [], { result, item in
            let qrCode = QRCodeData(item)
            let arr = Array(repeating: qrCode.code, count: qrCode.quantity)
            result.append(contentsOf: arr)
        })
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

    private func qrCode(with code: String) -> UIImage? {
        Log.debug("QR Code content:\n\(code)")
        for scale in (1...7).reversed() {
            if let img = QRCode.generate(for: code, scale: scale) {
                if img.size.width <= self.collectionView.bounds.width {
                    return img
                }
            }
        }

        return nil
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
