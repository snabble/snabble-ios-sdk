//
//  ScannerViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import UIKit
import Pulley

final class ScannerDrawerViewController: UIViewController {
    private var shoppingList: ShoppingList?
    private var shoppingListTableVC: ScannerShoppingListViewController

    private let shoppingCart: ShoppingCart
    private var shoppingCartVC: ShoppingCartViewController

    private let projectId: Identifier<Project>

    private var customAppearance: CustomAppearance?

    private weak var delegate: ShoppingCartDelegate?

    public weak var paymentMethodNavigationDelegate: PaymentMethodNavigationDelegate? {
        didSet {
            self.methodSelector?.paymentMethodNavigationDelegate = self.paymentMethodNavigationDelegate
        }
    }

    private var methodSelector: PaymentMethodSelector?

    private var previousPosition = PulleyPosition.closed

    @IBOutlet private var handleContainer: UIView!
    @IBOutlet private var handle: UIView!

    @IBOutlet private var itemCountLabel: UILabel!
    @IBOutlet private var totalPriceLabel: UILabel!

    @IBOutlet private var methodSelectionView: UIView!
    @IBOutlet private var methodIcon: UIImageView!
    @IBOutlet private var methodSpinner: UIActivityIndicatorView!
    @IBOutlet private var checkoutButton: UIButton!

    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var innerSpacer: UIView!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var separatorHeight: NSLayoutConstraint!

    init(_ projectId: Identifier<Project>, shoppingCart: ShoppingCart, delegate: ShoppingCartDelegate) {
        self.projectId = projectId
        self.shoppingCart = shoppingCart
        self.delegate = delegate

        self.shoppingListTableVC = ScannerShoppingListViewController(delegate: delegate)
        self.shoppingCartVC = ShoppingCartViewController(shoppingCart, delegate: delegate)

        super.init(nibName: nil, bundle: SnabbleBundle.main)

        SnabbleUI.registerForAppearanceChange(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        self.methodSelector = PaymentMethodSelector(self, self.methodSelectionView, self.methodIcon, self.shoppingCart)
        self.methodSelector?.paymentMethodNavigationDelegate = self.paymentMethodNavigationDelegate

        handle.layer.cornerRadius = 2
        handle.layer.masksToBounds = true
        handle.backgroundColor = .systemGray
        handle.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapped(_:)))
        handle.addGestureRecognizer(tap)

        segmentedControl.setTitle("Snabble.ShoppingList.title".localized(), forSegmentAt: 0)
        segmentedControl.setTitle("Snabble.ShoppingCart.title".localized(), forSegmentAt: 1)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        if #available(iOS 13.0, *) {
            let appearance = SnabbleUI.appearance
            segmentedControl.selectedSegmentTintColor = appearance.accentColor
            segmentedControl.setTitleTextAttributes([.foregroundColor: appearance.accentColor.contrast], for: .selected)
        }

        self.checkoutButton.addTarget(self, action: #selector(checkoutTapped(_:)), for: .touchUpInside)
        self.checkoutButton.setTitle("Snabble.Shoppingcart.buyProducts.now".localized(), for: .normal)
        self.checkoutButton.makeSnabbleButton()
        self.checkoutButton.setTitleColor(.systemGray, for: .disabled)

        self.methodSelectionView.layer.masksToBounds = true
        self.methodSelectionView.layer.cornerRadius = 8
        self.methodSelectionView.layer.borderColor = UIColor.lightGray.cgColor
        self.methodSelectionView.layer.borderWidth = 1 / UIScreen.main.scale

        self.totalPriceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)

        self.separatorHeight.constant = 1 / UIScreen.main.scale

        self.switchTo(shoppingListTableVC, in: contentView, duration: 0)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let custom = self.customAppearance {
            self.checkoutButton.setCustomAppearance(custom)
        }

        self.updateShoppingLists()
        self.methodSelector?.updateSelectionVisibility()
        self.updateTotals()
    }

    @objc private func handleTapped(_ gesture: UITapGestureRecognizer) {
        self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
    }

    @objc private func tabChanged(_ control: UISegmentedControl) {
        selectSegment(control.selectedSegmentIndex)
    }

    func switchTo(_ destination: UIViewController, in view: UIView, duration: TimeInterval = 0.15) {
        guard destination != children.first else {
            return
        }

        if let source = self.children.first {
            addChild(destination)
            source.willMove(toParent: nil)
            transition(from: source,
                       to: destination,
                       duration: duration,
                       options: .transitionCrossDissolve,
                       animations: {},
                       completion: { _ in
                           source.removeFromParent()
                           destination.didMove(toParent: self)
                       }
            )
        } else {
            addChild(destination)
            view.addSubview(destination.view)
            destination.didMove(toParent: self)
        }

        destination.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            destination.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            destination.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            destination.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            destination.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func updateShoppingLists() {
        let shoppingLists = ShoppingList.fetchListsFromDisk()
        shoppingList = shoppingLists.first { $0.projectId == projectId }
        if shoppingList?.isEmpty == true {
            shoppingList = nil
        }

        shoppingListTableVC.reload(shoppingList)

        let noList = shoppingList == nil
        segmentedControl?.isHidden = noList
        innerSpacer?.isHidden = noList
        if noList {
            selectSegment(1)
        }
    }

    func markScannedProduct(_ product: Product) {
        shoppingListTableVC.markScannedProduct(product)
    }

    func selectSegment(_ segment: Int) {
        segmentedControl.selectedSegmentIndex = segment
        let activeVC: UIViewController
        if segment == 0 {
            activeVC = self.shoppingListTableVC
        } else {
            activeVC = self.shoppingCartVC
        }

        self.switchTo(activeVC, in: contentView)
    }

    @objc private func shoppingCartUpdated(_ notification: Notification) {
        updateTotals()
    }

    private func updateTotals() {
        let numProducts = self.shoppingCart.numberOfProducts
        let formatter = PriceFormatter(SnabbleUI.project)
        let backendCartInfo = self.shoppingCart.backendCartInfo

        let nilPrice: Bool
        if let items = backendCartInfo?.lineItems {
            let productsNoPrice = items.filter { $0.type == .default && $0.totalPrice == nil }
            nilPrice = !productsNoPrice.isEmpty
        } else {
            nilPrice = false
        }

        let cartTotal = SnabbleUI.project.displayNetPrice ? backendCartInfo?.netPrice : backendCartInfo?.totalPrice

        let totalPrice = nilPrice ? nil : (cartTotal ?? self.shoppingCart.total)
        if let total = totalPrice, numProducts > 0 {
            let formattedTotal = formatter.format(total)
            self.totalPriceLabel?.text = formattedTotal
        } else {
            self.totalPriceLabel?.text = ""
        }

        let fmt = numProducts == 1 ? "Snabble.Shoppingcart.numberOfItems.one" : "Snabble.Shoppingcart.numberOfItems"
        self.itemCountLabel?.text = String(format: fmt.localized(), numProducts)

        self.methodSelector?.updateAvailablePaymentMethods()

        self.checkoutButton?.isEnabled = numProducts > 0 && (totalPrice ?? 0) >= 0
    }
}

// MARK: - pulley
extension ScannerDrawerViewController: PulleyDrawerViewControllerDelegate {
    public func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .collapsed, .open]
    }

    public func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return shoppingList == nil ? 138 : 188
    }

    public func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        let newPosition = drawer.drawerPosition
        shoppingListTableVC.tableView.isScrollEnabled = newPosition == .open

        if newPosition != previousPosition {
            let scanner = self.pulleyViewController?.primaryContentViewController as? ScanningViewController
            if previousPosition == .open {
                scanner?.resumeScanning()
            } else if newPosition == .open {
                scanner?.pauseScanning()
            }
            previousPosition = drawer.drawerPosition
        }
    }

    public func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        let height = self.view.bounds.height
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: height - distance, right: 0)
        shoppingListTableVC.tableView?.contentInset = insets
        shoppingListTableVC.tableView?.scrollIndicatorInsets = insets
        shoppingCartVC.tableView?.contentInset = insets
        shoppingCartVC.tableView?.scrollIndicatorInsets = insets

        let scanner = self.pulleyViewController?.primaryContentViewController as? ScanningViewController
        // using 80% of height as the maximum avoids an ugly trailing animation
        let offset = -min(distance, height * 0.8) / 2
        scanner?.setOverlayOffset(offset)
    }
}

// MARK: - appearance
extension ScannerDrawerViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.checkoutButton?.setCustomAppearance(appearance)
        self.customAppearance = appearance
    }
}

extension ScannerDrawerViewController: AnalyticsDelegate {
    func track(_ event: AnalyticsEvent) {
        self.delegate?.track(event)
    }
}

// MARK: - checkout stuff
extension ScannerDrawerViewController {
    @objc private func checkoutTapped(_ sender: Any) {
        self.startCheckout()
    }

    private func startCheckout() {
        selectSegment(1)

        let project = SnabbleUI.project
        guard
            self.delegate?.checkoutAllowed(project) == true,
            let paymentMethod = self.methodSelector?.selectedPaymentMethod
        else {
            // no payment method selected -> show the "add method" view
            if SnabbleUI.implicitNavigation {
                let selection = PaymentMethodAddViewController(showFromCart: true, self)
                self.navigationController?.pushViewController(selection, animated: true)
            } else {
                let msg = "navigationDelegate may not be nil when using explicit navigation"
                assert(self.paymentMethodNavigationDelegate != nil, msg)
                self.paymentMethodNavigationDelegate?.addMethod(fromCart: true)
            }

            return
        }

        // no detail data, and there is an editing VC? Show that instead of continuing
        if self.methodSelector?.selectedPaymentDetail == nil,
           paymentMethod.isAddingAllowed(showAlertOn: self),
           let editVC = paymentMethod.editViewController(with: project.id, showFromCart: true, self) {
            if SnabbleUI.implicitNavigation {
                self.navigationController?.pushViewController(editVC, animated: true)
            } else {
                let msg = "navigationDelegate may not be nil when using explicit navigation"
                assert(self.paymentMethodNavigationDelegate != nil, msg)
                self.paymentMethodNavigationDelegate?.addData(for: paymentMethod, in: project.id)
            }
            return
        }

        let button = self.checkoutButton!

        let spinner = UIActivityIndicatorView(style: .white)
        spinner.startAnimating()
        button.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        button.isEnabled = false

        let offlineMethods = SnabbleUI.project.paymentMethods.filter { $0.offline }
        let timeout: TimeInterval = offlineMethods.contains(paymentMethod) ? 3 : 10
        self.shoppingCart.createCheckoutInfo(SnabbleUI.project, timeout: timeout) { result in
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            button.isEnabled = true

            switch result {
            case .success(let info):
                self.delegate?.gotoPayment(paymentMethod, self.methodSelector?.selectedPaymentDetail, info, self.shoppingCart)
            case .failure(let error):
                let handled = self.delegate?.handleCheckoutError(error) ?? false
                if !handled {
                    if let offendingSkus = error.error.details?.compactMap({ $0.sku }) {
                        self.showProductError(offendingSkus)
                        return
                    }

                    switch error.error.type {
                    case .noAvailableMethod:
                        self.delegate?.showWarningMessage("Snabble.Payment.noMethodAvailable".localized())
                    case .invalidDepositVoucher:
                        self.delegate?.showWarningMessage("Snabble.invalidDepositVoucher.errorMsg".localized())
                    default:
                        if !offlineMethods.isEmpty {
                            let info = SignedCheckoutInfo(offlineMethods)
                            self.delegate?.gotoPayment(paymentMethod, self.methodSelector?.selectedPaymentDetail, info, self.shoppingCart)
                        } else {
                            self.delegate?.showWarningMessage("Snabble.Payment.errorStarting".localized())
                        }
                    }
                }
            }
        }
    }

    private func showProductError(_ skus: [String]) {
        var offendingProducts = [String]()
        for sku in skus {
            if let item = self.shoppingCart.items.first(where: { $0.product.sku == sku }) {
                offendingProducts.append(item.product.name)
            }
        }

        let start = offendingProducts.count == 1 ? "Snabble.saleStop.errorMsg.one" : "Snabble.saleStop.errorMsg"
        let msg = start.localized() + "\n\n" + offendingProducts.joined(separator: "\n")
        let alert = UIAlertController(title: "Snabble.saleStop.errorMsg.title".localized(), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}
