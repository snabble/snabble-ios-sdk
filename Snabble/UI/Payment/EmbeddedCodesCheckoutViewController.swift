//
//  EmbeddedCodesCheckoutViewController
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

class EmbeddedCodesCheckoutViewController: UIViewController {

    @IBOutlet weak var explanation1: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var explanation2: UILabel!
    @IBOutlet weak var paidButton: UIButton!

    private var initialBrightness: CGFloat = 0

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    private var process: CheckoutProcess!
    private weak var cart: ShoppingCart!
    private weak var delegate: PaymentDelegate!

    private var codeblocks = [[String]]()
    private var itemSize = CGSize(width: 100, height: 100)
    private let encodedCodes: EncodedCodes?

    init(_ process: CheckoutProcess, _ cart: ShoppingCart, _ delegate: PaymentDelegate) {
        self.process = process
        self.cart = cart
        self.delegate = delegate
        self.encodedCodes = SnabbleAPI.project.encodedCodes

        super.init(nibName: nil, bundle: Snabble.bundle)

        self.title = "Snabble.QRCode.title".localized()
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.paidButton.backgroundColor = SnabbleAppearance.shared.config.primaryColor
        self.paidButton.makeRoundedButton()
        self.paidButton.setTitle("Snabble.QRCode.didPay".localized(), for: .normal)

        let nib = UINib(nibName: "QRCodeCell", bundle: Snabble.bundle)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "qrCodeCell")

        self.setupCodeBlocks()

        self.pageControl.numberOfPages = self.codeblocks.count
        self.pageControl.pageIndicatorTintColor = .lightGray
        self.pageControl.currentPageIndicatorTintColor = SnabbleAppearance.shared.config.primaryColor
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

        let total = Price.format(cart.totalPrice)
        self.totalPriceLabel.text = "Snabble.QRCode.total".localized() + "\(total)"
        let explanation = self.codeblocks.count > 1 ? "Snabble.QRCode.showTheseCodes" : "Snabble.QRCode.showThisCode"
        self.explanation1.text = explanation.localized()
        self.explanation2.text = "Snabble.QRCode.priceMayDiffer".localized()
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

    private func setupCodeBlocks() {
        let maxCodes = (self.encodedCodes?.maxCodes ?? 100) - 1
        let (regularCodes, restrictedCodes) = self.codesForQR()

        var regularBlocks = self.blocksFor(regularCodes, maxCodes)
        var restrictedBlocks = self.blocksFor(restrictedCodes, maxCodes)

        // if possible, merge the last regular and the last restricted Block
        if regularBlocks.count > 1 && restrictedBlocks.count > 0 {
            let lastRegularBlock = regularBlocks.count - 1
            let lastRestrictedBlock = restrictedBlocks.count - 1
            if regularBlocks[lastRegularBlock].count + restrictedBlocks[lastRestrictedBlock].count < maxCodes {
                let final = restrictedBlocks[lastRestrictedBlock].remove(at: restrictedBlocks[lastRestrictedBlock].count-1)
                restrictedBlocks[lastRestrictedBlock].append(contentsOf: regularBlocks[lastRegularBlock])
                restrictedBlocks[lastRestrictedBlock].append(final)
                regularBlocks.remove(at: lastRegularBlock)
            }
        }

        // append "nextCode" to all blocks
        if let nextCode = self.encodedCodes?.nextCode {
            for i in 0..<regularBlocks.count - 1 {
                regularBlocks[i].append(nextCode)
            }
            for i in 0..<restrictedBlocks.count - 1 {
                restrictedBlocks[i].append(nextCode)
            }
        }

        if let nextCodeCheck = self.encodedCodes?.nextCodeWithCheck, restrictedCodes.count > 0 {
            let lastBlock = regularBlocks.count - 1
            if lastBlock >= 0 {
                // if we added a "nextCode" above, undo that for the last block
                if self.encodedCodes?.nextCode != nil {
                    let lastBlockSize = regularBlocks[lastBlock].count
                    regularBlocks[lastBlock].remove(at: lastBlockSize - 1)
                }
                // add the "nextCodeWithCheck" code
                regularBlocks[lastBlock].append(nextCodeCheck)
            } else {
                // there were no regular products, create a new regular block with just the `nextCodeCheck` code
                regularBlocks = [[nextCodeCheck]]
            }
        }

        self.codeblocks = regularBlocks
        self.codeblocks.append(contentsOf: restrictedBlocks)

        for (index, block) in self.codeblocks.enumerated() {
            print("block \(index): \(block.count) elements, first=\(block[0]), last=\(block[block.count-1])")
        }
    }

    private func codesForQR() -> ([String],[String]) {
        if self.encodedCodes?.nextCodeWithCheck != nil {
            let regularItems = self.cart.items.filter { return $0.product.saleRestriction == .none }
            let restrictedItems = self.cart.items.filter { return $0.product.saleRestriction != .none }

            var regularCodes = self.codesFor(regularItems)
            if let additionalCodes = self.cart.additionalCodes {
                regularCodes.append(contentsOf: additionalCodes)
            }

            var restrictedCodes = self.codesFor(restrictedItems)

            if let finalCode = self.encodedCodes?.finalCode {
                if restrictedCodes.count > 0 {
                    restrictedCodes.append(finalCode)
                } else {
                    regularCodes.append(finalCode)
                }
            }

            return (regularCodes, restrictedCodes)
        } else {
            var codes = self.codesFor(self.cart.items)
            if let additionalCodes = self.cart.additionalCodes {
                codes.append(contentsOf: additionalCodes)
            }
            if let finalCode = self.encodedCodes?.finalCode {
                codes.append(finalCode)
            }
            return (codes, [])
        }
    }

    private func codesFor(_ items: [CartItem]) -> [String] {
        return items.reduce(into: [], { result, item in
            if item.product.type == .userMustWeigh {
                // generate an EAN with the embedded weight
                if let template = item.product.weighedItemIds?.first {
                    let ean = EAN13.embedDataInEan(template, data: item.quantity)
                    result.append(ean)
                }
            } else {
                result.append(contentsOf: Array(repeating: item.scannedCode, count: item.quantity))
            }
        })
    }

    private func blocksFor(_ codes: [String], _ blockSize: Int) -> [[String]] {
        return stride(from: 0, to: codes.count, by: blockSize).map {
            Array(codes[$0 ..< min($0 + blockSize, codes.count)])
        }
    }

    private func setButtonTitle() {
        let title = self.pageControl.currentPage == self.codeblocks.count - 1 ? "Snabble.QRCode.didPay" : "Snabble.QRCode.nextCode"
        self.paidButton.setTitle(title.localized(), for: .normal)
    }

    @IBAction func paidButtonTapped(_ sender: UIButton) {
        if self.pageControl.currentPage != self.codeblocks.count - 1 {
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
        return self.codeblocks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "qrCodeCell", for: indexPath) as! QRCodeCell

        let img = self.qrCode(for: self.codeblocks[indexPath.row])
        cell.imageView.image = img
        cell.imageWidth.constant = img?.size.width ?? 0

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }

    private func qrCode(for codes: [String]) -> UIImage? {
        guard let encoding = self.encodedCodes else {
            return nil
        }

        let qrCodeContent = encoding.prefix + codes.joined(separator: encoding.separator) + encoding.suffix
        NSLog("QR Code content:\n\(qrCodeContent)")
        for scale in (1...7).reversed() {
            if let img = QRCode.generate(for: qrCodeContent, scale: scale) {
                if img.size.width <= self.collectionView.bounds.width {
                    return img
                }
            }
        }

        return nil
    }

    @IBAction func pageControlTapped(_ pageControl: UIPageControl) {
        if pageControl.currentPage < self.codeblocks.count {
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
