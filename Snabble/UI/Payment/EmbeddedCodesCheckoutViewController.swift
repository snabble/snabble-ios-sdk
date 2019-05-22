//
//  EmbeddedCodesCheckoutViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
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
    private var poller: PaymentProcessPoller?
    private var qrCodeConfig: QRCodeConfig

    private var codes = [String]()
    private var itemSize = CGSize(width: 100, height: 100)

    init(_ process: CheckoutProcess?, _ method: PaymentMethod, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.method = method
        self.cart = cart
        self.delegate = delegate
        self.qrCodeConfig = SnabbleUI.project.encodedCodes ?? QRCodeConfig.default

        super.init(nibName: nil, bundle: Snabble.bundle)

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

        let nib = UINib(nibName: "QRCodeCell", bundle: Snabble.bundle)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "qrCodeCell")

        switch self.method {
        case .encodedCodes:
            let codeblocks = Codeblocks(self.qrCodeConfig)
            let (regularCodes, restrictedCodes) = self.codesForQR()
            self.codes = codeblocks.generateQrCodes(regularCodes, restrictedCodes)
        case .encodedCodesCSV:
            self.codes = self.csvForQR()
        case .encodedCodesIKEA:
            self.codes = self.codesForIKEA()
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
        let explanation = self.codes.count > 1 ? "Snabble.QRCode.showTheseCodes" : "Snabble.QRCode.showThisCode"
        self.explanation1.text = explanation.localized()
        self.explanation2.text = "Snabble.QRCode.priceMayDiffer".localized()

        if total == nil {
            self.totalPriceLabel.isHidden = true
            self.explanation2.isHidden = true
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

    private func divideIntoChunks(_ lines: [String], maxSize: Int) -> [[String]] {
        let maxCodes = Float(maxSize)
        let linesCount = Float(lines.count)
        let chunks = (linesCount / maxCodes).rounded(.up)
        let chunkSize = Int((linesCount / chunks).rounded(.up))
        let blocks = stride(from: 0, to: lines.count, by: chunkSize).map { start -> [String] in
            return Array(lines[start ..< min(start + chunkSize, lines.count)])
        }
        return blocks
    }

    private func codesForIKEA() -> [String] {
        let lines = self.codesFor(self.cart.items)

        let chunks = self.divideIntoChunks(lines, maxSize: self.qrCodeConfig.maxCodes)

        let gs = "\u{001d}" // ASCII Group Separator
        let blocks = chunks.enumerated().map { index, block -> String in
            let header = "9100003"                  // AI 91 (origin type), 00003 == IKEA Store App
            let blocks = "10" + "0\(chunks.count)"  // AI 10 (lot number), # of chunks

            var result = header + gs + blocks

            // family card goes into the first code
            if let card = self.cart.loyaltyCard, index == 0 {
                let familyCard = "92" + card        // AI 92 (additional item id), card number
                result += gs + familyCard
            }

            let items = block.map { "240" + $0 }    // AI 240 (additional item is), item's scanned code
            return result + gs + items.joined(separator: gs)
        }

        return blocks
    }

    private func csvForQR() -> [String] {
        var lines = [String]()
        if let card = self.cart.loyaltyCard {
            lines.append("1;\(card)")
        }

        lines += self.cart.items.reduce(into: [], { result, item in
            let qrCode = item.dataForQR
            result.append("\(qrCode.quantity);\(qrCode.code)")
        })

        let chunks = self.divideIntoChunks(lines, maxSize: self.qrCodeConfig.maxCodes)
        // TODO: add N;M to header line, see https://github.com/snabble/docs/pull/60
        let blocks = chunks.map {
            return [ "snabble;" ] + $0
        }

        return blocks.map { $0.joined(separator: "\n") }
    }

    private func codesForQR() -> ([String],[String]) {
        let items = self.cart.items.sorted { $0.price < $1.price }

        if self.qrCodeConfig.nextCodeWithCheck != nil {
            let regularItems = items.filter { return $0.product.saleRestriction == .none }
            let restrictedItems = items.filter { return $0.product.saleRestriction != .none }

            var regularCodes = [String]()
            if let card = self.cart.loyaltyCard {
                regularCodes.append(card)
            }

            regularCodes += self.codesFor(regularItems)
            if let additionalCodes = self.cart.additionalCodes {
                regularCodes.append(contentsOf: additionalCodes)
            }
            let restrictedCodes = self.codesFor(restrictedItems)

            return (regularCodes, restrictedCodes)
        } else {
            var codes = [String]()
            if let card = self.cart.loyaltyCard {
                codes.append(card)
            }
            codes += self.codesFor(items)
            if let additionalCodes = self.cart.additionalCodes {
                codes.append(contentsOf: additionalCodes)
            }

            return (codes, [])
        }
    }

    private func codesFor(_ items: [CartItem]) -> [String] {
        return items.reduce(into: [], { result, item in
            let qrCode = item.dataForQR
            let arr = Array(repeating: qrCode.code, count: qrCode.quantity)
            result.append(contentsOf: arr)
        })
    }

    private func setButtonTitle() {
        let title = self.pageControl.currentPage == self.codes.count - 1 ? "Snabble.QRCode.didPay" : "Snabble.QRCode.nextCode"
        self.paidButton.setTitle(title.localized(), for: .normal)
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

            self.delegate.paymentFinished(true, self.cart)
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
