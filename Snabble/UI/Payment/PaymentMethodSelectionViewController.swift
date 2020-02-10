//
//  PaymentMethodSelectionViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public extension Notification.Name {
    static let paymentMethodsChanged = Notification.Name("paymentMethodsChanged")
}

final class PaymentMethodSelectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private weak var cart: ShoppingCart!
    private let process: PaymentProcess
    private let signedCheckoutInfo: SignedCheckoutInfo
    private var itemSize = CGSize.zero

    private var paymentMethods: [PaymentMethod]

    init(_ process: PaymentProcess, _ paymentMethods: [PaymentMethod]) {
        self.process = process
        self.signedCheckoutInfo = process.signedCheckoutInfo
        self.cart = process.cart
        self.paymentMethods = paymentMethods

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.title = "Snabble.PaymentSelection.title".localized()

        super.viewDidLoad()

        let formatter = PriceFormatter(SnabbleUI.project)
        let totalPrice = formatter.format(self.signedCheckoutInfo.checkoutInfo.price.price)

        self.title = String(format: "Snabble.PaymentSelection.payNow".localized(), totalPrice)

        let nib = UINib(nibName: "PaymentMethodCell", bundle: SnabbleBundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "paymentCell")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = self.collectionView.frame.width
        self.itemSize = CGSize(width: width, height: 120)

        self.updateContentInset()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.isBeingPresented && !self.isMovingToParent {
            // whatever was covering us has been dismissed or popped
            self.updatePaymentMethods()
        }

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartChanged(_:)), name: .snabbleCartUpdated, object: nil)
        nc.addObserver(self, selector: #selector(self.paymentMethodsChanged(_:)), name: .paymentMethodsChanged, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.process.track(.viewPaymentMethodSelection)
    }

    @objc private func shoppingCartChanged(_ notification: Notification) {
        // if we're the top VC and not already disappearing, pop.
        if let top = self.navigationController?.topViewController as? PaymentMethodSelectionViewController, !top.isMovingFromParent {
            self.navigationController?.popViewController(animated: false)
        }
    }

    @objc private func paymentMethodsChanged(_ notification: Notification) {
        self.updatePaymentMethods()
    }

    private func updatePaymentMethods() {
        let infoMethods = self.signedCheckoutInfo.checkoutInfo.paymentMethods
        let mergedMethods = self.process.mergePaymentMethodList(infoMethods)
        self.paymentMethods = self.process.filterPaymentMethods(mergedMethods)
        self.collectionView.reloadData()
        self.view.setNeedsLayout()
    }

    private func updateContentInset() {
        let numRows = self.paymentMethods.count
        var contentInsetTop = self.collectionView.bounds.size.height

        for i in 0 ..< numRows {
            let attributes = self.collectionView.layoutAttributesForItem(at: IndexPath(item: i, section: 0))
            let rowRect = attributes?.frame ?? CGRect.zero
            contentInsetTop -= rowRect.size.height + (i > 0 ? 16 : 0)
            if contentInsetTop <= 0 {
                contentInsetTop = 0
            }
        }

        self.collectionView.contentInset = UIEdgeInsets.init(top: contentInsetTop, left: 0, bottom: 0, right: 0)
        if contentInsetTop == 0 {
            // scroll so that the last entry is fully visible
            let last = IndexPath(item: numRows-1, section: 0)
            self.collectionView.scrollToItem(at: last, at: .bottom, animated: false)
        }
    }

    fileprivate func startPayment(_ method: PaymentMethod) {
        self.process.start(method) { result in
            switch result {
            case .success(let viewController):
                self.navigationController?.pushViewController(viewController, animated: true)
            case .failure(let error):
                let handled = self.process.delegate.handlePaymentError(method, error)
                if !handled {
                    self.process.delegate.showWarningMessage("Snabble.Payment.errorStarting".localized())
                }
            }
        }
    }

}

// MARK: - collection view delegates
extension PaymentMethodSelectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.paymentMethods.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "paymentCell", for: indexPath) as! PaymentMethodCell

        let paymentMethod = self.paymentMethods[indexPath.row]
        cell.paymentMethod = paymentMethod
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let method = self.paymentMethods[indexPath.row]

        if method.data == nil, let entryVC = self.process.delegate.dataEntry(for: method) {
            self.navigationController?.pushViewController(entryVC, animated: true)
            return
        }
        
        self.process.delegate.startPayment(method, self) { proceed in
            if proceed {
                self.startPayment(method)
            }
        }
    }
}

// MARK: - Appearance change
extension PaymentMethodSelectionViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }

            self.collectionView.reloadData()
        }
    }
}
