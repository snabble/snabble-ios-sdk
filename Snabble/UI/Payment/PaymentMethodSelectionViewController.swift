//
//  PaymentMethodSelectionViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

public extension Notification.Name {
    static let paymentMethodsChanged = Notification.Name("paymentMethodsChanged")
}

public protocol PaymentNavigationDelegate: class {
    func processStarted(_ method: PaymentMethod, _ process: CheckoutProcess)
    func dataEntryNeeded(for method: PaymentMethod)
}

public final class PaymentMethodSelectionViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!

    private weak var cart: ShoppingCart!
    private let process: PaymentProcess
    private let signedCheckoutInfo: SignedCheckoutInfo
    private var itemSize = CGSize.zero

    private var paymentMethods: [PaymentMethod]
    private weak var analyticsDelegate: AnalyticsDelegate?

    public weak var navigationDelegate: PaymentNavigationDelegate?

    private var contentInsetUpdated = false

    public init(_ process: PaymentProcess, _ paymentMethods: [PaymentMethod], _ analyticsDelegate: AnalyticsDelegate) {
        self.process = process
        self.signedCheckoutInfo = process.signedCheckoutInfo
        self.cart = process.cart
        self.paymentMethods = paymentMethods
        self.analyticsDelegate = analyticsDelegate

        super.init(nibName: nil, bundle: SnabbleBundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        self.title = "Snabble.PaymentSelection.title".localized()

        super.viewDidLoad()

        let formatter = PriceFormatter(SnabbleUI.project)
        let totalPrice = formatter.format(self.signedCheckoutInfo.checkoutInfo.price.price)

        self.title = String(format: "Snabble.PaymentSelection.payNow".localized(), totalPrice)

        let nib = UINib(nibName: "CheckoutPaymentMethodCell", bundle: SnabbleBundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "paymentCell")

        if !SnabbleUI.implicitNavigation && self.navigationDelegate == nil {
            let msg = "navigationDelegate may not be nil when using explicit navigation"
            assert(self.navigationDelegate != nil, msg)
            Log.error(msg)
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = self.collectionView.frame.width
        self.itemSize = CGSize(width: width, height: 120)

        self.updateContentInset()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.isBeingPresented && !self.isMovingToParent {
            // whatever was covering us has been dismissed or popped
            self.updatePaymentMethods()
        }

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartChanged(_:)), name: .snabbleCartUpdated, object: nil)
        nc.addObserver(self, selector: #selector(self.paymentMethodsChanged(_:)), name: .paymentMethodsChanged, object: nil)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.contentInsetUpdated = true
        self.process.track(.viewPaymentMethodSelection)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.contentInsetUpdated = false
    }

    @objc private func shoppingCartChanged(_ notification: Notification) {
        guard SnabbleUI.implicitNavigation else {
            return
        }

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
        guard !self.contentInsetUpdated else {
            return
        }

        let numRows = self.paymentMethods.count
        var contentInsetTop = self.collectionView.bounds.size.height

        for row in 0 ..< numRows {
            let attributes = self.collectionView.layoutAttributesForItem(at: IndexPath(item: row, section: 0))
            let rowRect = attributes?.frame ?? CGRect.zero
            contentInsetTop -= rowRect.size.height + (row > 0 ? 16 : 0)
            if contentInsetTop <= 0 {
                contentInsetTop = 0
            }
        }

        self.collectionView.contentInset = UIEdgeInsets(top: contentInsetTop, left: 0, bottom: 0, right: 0)
        if contentInsetTop == 0 {
            // scroll so that the last entry is fully visible
            let last = IndexPath(item: numRows - 1, section: 0)
            self.collectionView.scrollToItem(at: last, at: .bottom, animated: false)
        }
    }

    fileprivate func startPayment(_ method: PaymentMethod) {
        if SnabbleUI.implicitNavigation {
            self.process.start(method) { (result: Result<UIViewController, SnabbleError>) in
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
        } else {
            self.process.start(method) { (result: RawResult<CheckoutProcess, SnabbleError>) in
                switch result.result {
                case .success(let process):
                    self.navigationDelegate?.processStarted(method, process)
                case .failure(let error):
                    let handled = self.process.delegate.handlePaymentError(method, error)
                    if !handled {
                        self.process.delegate.showWarningMessage("Snabble.Payment.errorStarting".localized())
                    }
                }
            }
        }
    }

}

// MARK: - collection view delegates
extension PaymentMethodSelectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.paymentMethods.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "paymentCell", for: indexPath) as! CheckoutPaymentMethodCell

        let paymentMethod = self.paymentMethods[indexPath.row]
        cell.paymentMethod = paymentMethod

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let method = self.paymentMethods[indexPath.row]

        if method.dataRequired && method.data == nil {
            if SnabbleUI.implicitNavigation, let entryVC = self.dataEntryController(for: method) {
                self.navigationController?.pushViewController(entryVC, animated: true)
            } else {
                self.navigationDelegate?.dataEntryNeeded(for: method)
            }
            return
        }

        self.process.delegate.startPayment(method, self) { proceed in
            if proceed {
                self.startPayment(method)
            }
        }
    }

    private func dataEntryController(for method: PaymentMethod) -> UIViewController? {
        switch method {
        case .deDirectDebit:
            return SepaEditViewController(nil, nil, self.analyticsDelegate)
        case .visa:
            return CreditCardEditViewController(.visa, self.analyticsDelegate)
        case .mastercard:
            return CreditCardEditViewController(.mastercard, self.analyticsDelegate)
        case .americanExpress:
            return CreditCardEditViewController(.amex, self.analyticsDelegate)
        case .paydirektOneKlick:
            return PaydirektEditViewController(nil, nil, self.analyticsDelegate)

        case .qrCodePOS, .qrCodeOffline, .externalBilling, .gatekeeperTerminal, .customerCardPOS:
            return nil
        }
    }
}

// MARK: - Appearance change
extension PaymentMethodSelectionViewController {
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }

            self.collectionView.reloadData()
        }
    }
}
