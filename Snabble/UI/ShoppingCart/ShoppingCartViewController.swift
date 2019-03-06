//
//  ShoppingCartViewController.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

/// a protocol that users of `ShoppingCartViewController` must implement
public protocol ShoppingCartDelegate: AnalyticsDelegate, MessageDelegate {

    /// called to determine if checking out is possible, e.g. if required customer card data is present
    /// it is this mehtod's responsibility to display corresponding error messages
    func checkoutAllowed(_ project: Project) -> Bool

    /// called when the user wants to initiate payment.
    /// Implementations should usually create a `PaymentProcess` instance and invoke its `start` method
    func gotoPayment(_ info: SignedCheckoutInfo, _ cart: ShoppingCart)

    /// called when the "Scan Products" button in the cart's empty state is tapped
    func gotoScanner()

    /// called when an error occurred
    ///
    /// - Parameter error: the error from the backend
    /// - Returns: true if the error has been dealt with and no error messages need to be shown from the SDK
    func handleCheckoutError(_ error: SnabbleError) -> Bool

    func getLoyaltyCard(_ project: Project) -> String?
}

extension ShoppingCartDelegate {
    public func checkoutAllowed(_ project: Project) -> Bool {
        return true
    }

    public func handleCheckoutError(_ error: SnabbleError) -> Bool {
        return false
    }

    public func getLoyaltyCard(_ project: Project) -> String? {
        return nil
    }
}

enum CartTableEntry {
    case cartItem(CartItem, CheckoutInfo.LineItem?)
    case lineItem(CheckoutInfo.LineItem)
}
 
public final class ShoppingCartViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tableBottomMargin: NSLayoutConstraint!
    @IBOutlet private weak var checkoutButton: UIButton!

    private var editButton: UIBarButtonItem!
    private var trashButton: UIBarButtonItem!

    private var emptyState: ShoppingCartEmptyStateView!

    private let itemCellIdentifier = "itemCell"

    fileprivate var shoppingCart: ShoppingCart! {
        didSet {
            self.setupItems(self.shoppingCart)
            self.tableView?.reloadData()
            self.updateTotals()
        }
    }

    private var keyboardObserver: KeyboardObserver!
    private weak var delegate: ShoppingCartDelegate!

    private var items = [CartTableEntry]()
    
    public init(_ cart: ShoppingCart, delegate: ShoppingCartDelegate) {
        super.init(nibName: nil, bundle: Snabble.bundle)

        self.delegate = delegate

        self.title = "Snabble.ShoppingCart.title".localized()
        self.tabBarItem.image = UIImage.fromBundle("icon-cart")

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.updateShoppingCart(_:)), name: .snabbleCartUpdated, object: nil)

        self.keyboardObserver = KeyboardObserver(handler: self)

        self.shoppingCart = cart
    }

    func setupItems(_ cart: ShoppingCart) {
        self.items = []
        for item in cart.items {
            let lineItem = cart.backendCartInfo?.lineItems.first(where: { $0.cartItemId == item.uuid })
            let item = CartTableEntry.cartItem(item, lineItem)
            self.items.append(item)
        }

        let count = self.items.count
        print("setupItems: \(count) cartItems")
        if let lineItems = cart.backendCartInfo?.lineItems {
            for lineItem in lineItems where lineItem.cartItemId == nil {
                let item = CartTableEntry.lineItem(lineItem)
                self.items.append(item)
            }
        }

        let line = self.items.count - count
        print("setupItems: \(line) lineItems")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let primaryBackgroundColor = SnabbleUI.appearance.primaryBackgroundColor
        self.view.backgroundColor = primaryBackgroundColor

        self.emptyState = ShoppingCartEmptyStateView({ [weak self] in self?.showScanner() })
        self.emptyState.addTo(self.view)

        self.tableView.register(UINib(nibName: "ShoppingCartTableCell", bundle: Snabble.bundle), forCellReuseIdentifier: self.itemCellIdentifier)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 88

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl = refreshControl

        self.editButton = UIBarButtonItem(title: "Snabble.Edit".localized(), style: .plain, target: self, action: #selector(self.toggleEditingMode(_:)))
        self.editButton.possibleTitles = Set(["Snabble.Edit".localized(), "Snabble.Done".localized()])

        self.trashButton = UIBarButtonItem(image: UIImage.fromBundle("icon-trash"), style: .plain, target: self, action: #selector(self.trashButtonTapped(_:)))

        self.tableBottomMargin.constant = 0

        self.checkoutButton.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        self.checkoutButton.backgroundColor = SnabbleUI.appearance.primaryColor
        self.checkoutButton.tintColor = SnabbleUI.appearance.secondaryColor
        self.checkoutButton.makeRoundedButton()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateView()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewShoppingCart)

        // WTF? without this code, the button text sometimes appears as .textColor :(
        self.checkoutButton.tintColor = SnabbleUI.appearance.secondaryColor
        self.checkoutButton.titleLabel?.textColor = SnabbleUI.appearance.secondaryColor
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // turn off table editing, and re-enable everything that is disabled while editing
        self.isEditing = false
        self.editButton.title = "Snabble.Edit".localized()
        self.tableView.isEditing = false
    }

    public func setShoppingCart(_ cart: ShoppingCart) {
        self.shoppingCart = cart
    }

    private func setEditButton() {
        let navItem = self.navigationItem
        let items = self.items.count
        navItem.rightBarButtonItem = items == 0 ? nil : self.editButton
    }
    
    private func setDeleteButton() {
        let navItem = self.navigationItem
        navItem.leftBarButtonItem = self.isEditing ? self.trashButton : nil
    }

    // MARK: notification handlers
    @objc private func updateShoppingCart(_ notification: Notification) {
        self.setupItems(self.shoppingCart)
        self.tableView.reloadData()
        self.updateTotals()
    }

    @objc private func toggleEditingMode(_ sender: UIBarButtonItem) {
        self.setEditingMode(!self.isEditing)
    }
    
    private func setEditingMode(_ editing: Bool) {
        self.isEditing = editing

        self.tableView.setEditing(editing, animated: false)

        self.editButton.title = editing ? "Snabble.Done".localized() : "Snabble.Edit".localized()
        self.setDeleteButton()

        self.tableView.reloadData()
        self.tableView.setNeedsLayout()
    }

    @objc private func trashButtonTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Snabble.Shoppingcart.removeItems".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { action in
            self.delegate.track(.deletedEntireCart)
            self.shoppingCart.removeAll()
            self.updateView()
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    @objc private func handleRefresh(_ sender: Any) {
        self.shoppingCart.createCheckoutInfo(userInitiated: true) { success in
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.updateTotals()
        }
    }

    private func updateView() {
        self.setupItems(self.shoppingCart)
        self.tableView.reloadData()

        self.setEditButton()
        self.setDeleteButton()
        
        let items = self.items.count
        if items == 0 {
            self.setEditingMode(false)
        }

        self.updateTotals()
    }

    @IBAction func checkoutTapped(_ sender: UIButton) {
        self.startCheckout()
    }

    private func startCheckout() {
        let project = SnabbleUI.project
        guard self.delegate.checkoutAllowed(project) else {
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

        self.shoppingCart.loyaltyCard = self.delegate.getLoyaltyCard(project)
        
        self.shoppingCart.createCheckoutInfo(SnabbleUI.project, timeout: 10) { result in
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            button.isEnabled = true

            switch result {
            case .success(let info):
                self.delegate.gotoPayment(info, self.shoppingCart)
            case .failure(let error):
                let handled = self.delegate.handleCheckoutError(error)
                if !handled {
                    if let offendingSkus = error.error.details?.compactMap({ $0.sku }) {
                        self.showProductError(offendingSkus)
                        return
                    }

                    // app didn't handle the error. see if we can use embedded QR codes anyway
                    let project = SnabbleUI.project
                    if project.encodedCodes != nil {
                        // yes we can
                        let info = SignedCheckoutInfo()
                        self.delegate.gotoPayment(info, self.shoppingCart)
                    } else {
                        self.delegate.showWarningMessage("Snabble.Payment.errorStarting".localized())
                    }
                }
            }
        }
    }

    func showScanner() {
        self.delegate.gotoScanner()
    }

    private func showProductError(_ skus: [String]) {
        var offendingProducts = [String]()
        for sku in skus {
            if let item = self.shoppingCart.items.first(where: { $0.product.sku == sku }) {
                offendingProducts.append(item.product.name)
            }
        }

        let start = offendingProducts.count == 1 ? "Snabble.saleStop.errorMsg.one" : "Snabble.saleStop.errorMsg"
        let msg = start.localized() + "\n" + offendingProducts.joined(separator: "\n")
        let alert = UIAlertController(title: "Snabble.saleStop.errorMsg.title".localized(), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    func updateTotals() {
        let count = self.shoppingCart.numberOfProducts

        let formatter = PriceFormatter(SnabbleUI.project)
        let title: String
        let totalPrice = self.shoppingCart.backendCartInfo?.totalPrice ?? self.shoppingCart.total
        if let total = totalPrice, count > 0 {
            let formattedTotal = formatter.format(total)
            let fmt = count == 1 ? "Snabble.Shoppingcart.buyProducts.one" : "Snabble.Shoppingcart.buyProducts"
            title = String(format: fmt.localized(), count, formattedTotal)
            self.tabBarItem.title = formattedTotal
        } else {
            self.tabBarItem.title = "Snabble.ShoppingCart.title".localized()
            title = "Snabble.Shoppingcart.buyProducts.now".localized()
        }

        UIView.performWithoutAnimation {
            self.checkoutButton?.setTitle(title, for: .normal)
            self.checkoutButton?.layoutIfNeeded()
        }

        self.checkoutButton?.isHidden = count == 0
    }

}

extension ShoppingCartViewController: ShoppingCartTableDelegate {

    func confirmDeletion(at row: Int) {
        guard case .cartItem(let item, _) = self.items[row] else {
            return
        }

        let product = item.product

        let msg = String(format: "Snabble.Shoppingcart.removeItem".localized(), product.name)
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { action in
            self.deleteRow(row)
        })

        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel) { action in
            self.shoppingCart.setQuantity(1, at: row)
            let indexPath = IndexPath(row: row, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        })

        self.present(alert, animated: true)
    }

    func updateQuantity(_ quantity: Int, at row: Int) {
        guard case .cartItem = self.items[row] else {
            return
        }

        self.shoppingCart.setQuantity(quantity, at: row)
        self.updateView()
    }
}

extension ShoppingCartViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: table view data source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = self.items.count
        self.emptyState.isHidden = rows > 0
        return rows
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.itemCellIdentifier, for: indexPath) as! ShoppingCartTableCell
        guard indexPath.row < self.items.count else {
            return cell
        }

        let item = self.items[indexPath.row]
        switch item {
        case .cartItem(let item, let lineItem):
            cell.setCartItem(item, lineItem, row: indexPath.row, delegate: self)
        case .lineItem(let lineItem):
            cell.setLineItem(lineItem, row: indexPath.row, delegate: self)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteRow(indexPath.row)
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < self.items.count else {
            return false
        }

        let item = self.items[indexPath.row]

        switch item {
        case .cartItem: return true
        case .lineItem: return false
        }
    }

    // MARK: table view delegate

    // call tableView.deleteRows(at:) inside a CATransaction block so that we can reload the tableview afterwards
    func deleteRow(_ row: Int) {
        guard row < self.items.count, case .cartItem(let item, _) = self.items[row] else {
            return
        }

        let product = item.product
        self.delegate.track(.deletedFromCart(product.sku))

        self.items.remove(at: row)

        let indexPath = IndexPath(row: row, section: 0)
        CATransaction.begin()
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()

        CATransaction.setCompletionBlock {
            self.shoppingCart.remove(at: row)
            self.updateView()
        }

        CATransaction.commit()
    }

    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Snabble.remove".localized()
    }
}

// MARK: keyboard show/hide
extension ShoppingCartViewController: KeyboardHandling {

    func keyboardWillShow(_ info: KeyboardInfo) {
        guard self.view.window != nil else {
            return
        }

        // compensate for the opaque tab bar
        let tabBarHeight = self.tabBarController?.tabBar.frame.height ?? 0
        self.tableBottomMargin.constant = info.keyboardHeight - tabBarHeight
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

    func keyboardWillHide(_ info: KeyboardInfo) {
        guard self.view.window != nil else {
            return
        }

        self.tableBottomMargin.constant = 0
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }

}

