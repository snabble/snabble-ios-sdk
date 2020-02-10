//
//  ShoppingCartViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

/// a protocol that users of `ShoppingCartViewController` must implement
public protocol ShoppingCartDelegate: AnalyticsDelegate, MessageDelegate {
    /// called to determine if checking out is possible, e.g. if required customer card data is present
    /// it is this method's responsibility to display corresponding error messages
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
}

extension ShoppingCartDelegate {
    public func checkoutAllowed(_ project: Project) -> Bool {
        return true
    }

    public func handleCheckoutError(_ error: SnabbleError) -> Bool {
        return false
    }
}

enum CartTableEntry {
    // out main item and any additional line items referring to it
    case cartItem(CartItem, [CheckoutInfo.LineItem])

    // a new main item from the backend, plus its additional items.
    case lineItem(CheckoutInfo.LineItem, [CheckoutInfo.LineItem])

    // a giveaway
    case giveaway(CheckoutInfo.LineItem)

    // sums up the total discounts
    case discount(Int)
}
 
public final class ShoppingCartViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tableBottomMargin: NSLayoutConstraint!
    @IBOutlet private weak var checkoutButton: UIButton!

    private var trashButton: UIBarButtonItem!

    private var emptyState: ShoppingCartEmptyStateView!
    private var limitAlert: UIAlertController?
    private var customAppearance: CustomAppearance?

    private let itemCellIdentifier = "itemCell"

    public var shoppingCart: ShoppingCart! {
        didSet {
            self.setupItems(self.shoppingCart)
            self.tableView?.reloadData()
            self.updateTotals()
        }
    }

    private var keyboardObserver: KeyboardObserver!
    private weak var delegate: ShoppingCartDelegate!

    private var items = [CartTableEntry]()

    private var knownImages = Set<String>()
    internal var showImages = false
    
    public init(_ cart: ShoppingCart, delegate: ShoppingCartDelegate) {
        super.init(nibName: nil, bundle: SnabbleBundle.main)

        self.delegate = delegate

        self.title = "Snabble.ShoppingCart.title".localized()
        self.tabBarItem.image = UIImage.fromBundle(cart.numberOfProducts == 0 ? "SnabbleSDK/icon-cart-inactive-empty" : "SnabbleSDK/icon-cart-inactive-full")
        self.tabBarItem.selectedImage = UIImage.fromBundle("SnabbleSDK/icon-cart-active")

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.updateShoppingCart(_:)), name: .snabbleCartUpdated, object: nil)

        self.keyboardObserver = KeyboardObserver(handler: self)

        self.shoppingCart = cart
    }

    private func setupItems(_ cart: ShoppingCart) {
        self.items = []

        // find all line items that refer to our own cart items
        for (index, cartItem) in cart.items.enumerated() {
            if let lineItems = cart.backendCartInfo?.lineItems {
                let items = lineItems.filter { $0.id == cartItem.uuid || $0.refersTo == cartItem.uuid }

                // if we have a single lineItem that updates this entry with another SKU,
                // propagate the change to the shopping cart
                if let lineItem = items.first, items.count == 1, lineItem.sku != cartItem.product.sku {
                    let provider = SnabbleAPI.productProvider(for: SnabbleUI.project)
                    if let replacement = CartItem(replacing: cartItem, provider, self.shoppingCart.shopId, lineItem) {
                        cart.replaceItem(at: index, with: replacement)
                    }
                }
                let item = CartTableEntry.cartItem(cartItem, items)
                self.items.append(item)
            } else {
                let item = CartTableEntry.cartItem(cartItem, [])
                self.items.append(item)
            }
        }

        // now gather the remaining lineItems. find the "master" items first
        if let lineItems = cart.backendCartInfo?.lineItems {
            let cartIds = Set(cart.items.map { $0.uuid })

            let masterItems = lineItems.filter { $0.type == .default && !cartIds.contains($0.id) }

            for item in masterItems {
                let additionalItems = lineItems.filter { $0.type != .default && $0.refersTo == item.id }
                let item = CartTableEntry.lineItem(item, additionalItems)
                self.items.append(item)
            }
        }

        // find all giveaways
        if let lineItems = cart.backendCartInfo?.lineItems {
            let giveaways = lineItems.filter { $0.type == .giveaway }
            giveaways.forEach {
                self.items.append(CartTableEntry.giveaway($0))
            }
        }

        // find all discounts
        if let lineItems = cart.backendCartInfo?.lineItems {
            let discounts = lineItems.filter { $0.type == .discount }
            if discounts.count > 0 {
                let sum = discounts.reduce(0) { $0 + $1.amount * ($1.price ?? 0) }
                let item = CartTableEntry.discount(sum)
                self.items.append(item)
            }
        }

        // check if any of the cart items's products has an associated image
        let imgIndex = cart.items.firstIndex { $0.product.imageUrl != nil }
        self.showImages = imgIndex != nil
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = SnabbleUI.appearance.backgroundColor

        self.emptyState = ShoppingCartEmptyStateView({ [weak self] button in self?.emptyStateButtonTapped(button) })
        self.emptyState.addTo(self.view)

        self.tableView.register(UINib(nibName: "ShoppingCartTableCell", bundle: SnabbleBundle.main), forCellReuseIdentifier: self.itemCellIdentifier)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = UIColor.clear

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 78

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl = refreshControl

        self.trashButton = UIBarButtonItem(image: UIImage.fromBundle("SnabbleSDK/icon-trash"), style: .plain, target: self, action: #selector(self.trashButtonTapped(_:)))

        self.tableBottomMargin.constant = 0

        self.checkoutButton.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        self.checkoutButton.makeSnabbleButton()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateView()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate.track(.viewShoppingCart)

        if let custom = self.customAppearance {
            self.checkoutButton.setCustomAppearance(custom)
        }

        if !self.isBeingPresented && !self.isMovingToParent {
            // whatever was covering us has been dismissed or popped

            // re-send our current cart to the backend so that the supervisor can see us shopping again
            CartEvent.cart(self.shoppingCart)
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // turn off table editing, and re-enable everything that is disabled while editing
        self.isEditing = false
        self.setEditing(false, animated: false)
        self.tableView.isEditing = false
    }

    private func setEditButton() {
        let navItem = self.navigationItem
        let items = self.items.count
        navItem.rightBarButtonItem = items == 0 ? nil : self.editButtonItem
    }
    
    private func setDeleteButton() {
        let navItem = self.navigationItem
        navItem.leftBarButtonItem = self.isEditing ? self.trashButton : nil
    }

    private var restoreTimer: Timer?

    // MARK: notification handlers
    @objc private func updateShoppingCart(_ notification: Notification) {
        self.setupItems(self.shoppingCart)
        self.tableView?.reloadData()

        self.updateTotals()
        self.getMissingImages()

        if self.shoppingCart?.items.count == 0 && self.shoppingCart.backupAvailable {
            self.emptyState?.button1.setTitle("Snabble.Shoppingcart.emptyState.restartButtonTitle".localized(), for: .normal)
            self.emptyState?.button2.isHidden = false
            let restoreInterval: TimeInterval = 5 * 60
            self.restoreTimer = Timer.scheduledTimer(withTimeInterval: restoreInterval, repeats: false) { [weak self] timer in
                UIView.animate(withDuration: 0.2) {
                    self?.emptyState?.button1.setTitle("Snabble.Shoppingcart.emptyState.buttonTitle".localized(), for: .normal)
                    self?.emptyState?.button2.isHidden = true
                    self?.restoreTimer = nil
                }
            }
        } else {
            self.emptyState?.button2.isHidden = true
        }
    }

    private func getMissingImages() {
        let allImages: [String] = self.items.compactMap {
            guard case .cartItem(let item, _) = $0 else {
                return nil
            }

            return item.product.imageUrl
        }

        let images = Set(allImages)
        let newImages = images.subtracting(self.knownImages)
        for img in newImages {
            guard let url = URL(string: img) else {
                continue
            }
            let task = URLSession.shared.dataTask(with: url) { _,_,_ in }
            task.resume()
        }
        self.knownImages = images
    }

    override public func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)

        self.setDeleteButton()
    }

    @objc private func trashButtonTapped(_ sender: UIBarButtonItem) {
        self.showDeleteCartAlert()
    }

    @objc private func handleRefresh(_ sender: Any) {
        self.shoppingCart.createCheckoutInfo(userInitiated: true) { success in
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.updateTotals()
        }
    }

    public func showDeleteCartAlert() {
        let alert = UIAlertController(title: "Snabble.Shoppingcart.removeItems".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { action in
            self.delegate.track(.deletedEntireCart)
            self.shoppingCart.removeAll()
            self.updateView()
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    private func updateView(at row: Int? = nil) {
        let currentCount = self.items.count
        self.setupItems(self.shoppingCart)
        if self.items.count != currentCount {
            self.tableView.reloadData()
        } else {
            if let row = row {
                UIView.performWithoutAnimation {
                    let offset = self.tableView.contentOffset
                    let indexPath = IndexPath(row: row, section: 0)
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    self.tableView.contentOffset = offset
                }
            } else {
                if self.items.count > 0 {
                    self.tableView.reloadData()
                }
            }
        }


        self.setEditButton()
        self.setDeleteButton()
        self.emptyState.isHidden = self.items.count > 0

        // ugly workaround for visual glitch :(
        let items = self.items.count
        if items == 0 && self.isEditing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setEditing(false, animated: false)
            }
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

                    if error.error.type == .noAvailableMethod {
                        self.delegate.showWarningMessage("Snabble.Payment.noMethodAvailable".localized())
                        return
                    }

                    // app didn't handle the error. see if the project has a offline-capable payment method
                    let offlineMethods = SnabbleUI.project.paymentMethods.filter { $0.offline }
                    if offlineMethods.count > 0 {
                        let info = SignedCheckoutInfo(offlineMethods)
                        self.delegate.gotoPayment(info, self.shoppingCart)
                    } else {
                        self.delegate.showWarningMessage("Snabble.Payment.errorStarting".localized())
                    }
                }
            }
        }
    }

    private func emptyStateButtonTapped(_ button: UIButton) {
        switch button.tag {
        case 0: self.showScanner()
        case 1: self.restoreCart()
        default: ()
        }
    }

    private func showScanner() {
        self.delegate.gotoScanner()
    }

    private func restoreCart() {
        self.shoppingCart.restoreCart()
        self.updateView()
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

    public func updateTotals() {
        let count = self.shoppingCart.numberOfProducts

        self.tabBarItem.image = UIImage.fromBundle(count == 0 ? "SnabbleSDK/icon-cart-inactive-empty" : "SnabbleSDK/icon-cart-inactive-full")

        let formatter = PriceFormatter(SnabbleUI.project)
        let title: String

        /// workaround for backend giving us 0 as price for price-less products :(
        let nilPrice: Bool
        if let items = self.shoppingCart.backendCartInfo?.lineItems, items.first(where: { $0.totalPrice == nil} ) != nil {
            nilPrice = true
        } else {
            nilPrice = false
        }

        let totalPrice = nilPrice ? nil : (self.shoppingCart.backendCartInfo?.totalPrice ?? self.shoppingCart.total)
        if let total = totalPrice, count > 0 {
            let formattedTotal = formatter.format(total)
            let fmt = count == 1 ? "Snabble.Shoppingcart.buyProducts.one" : "Snabble.Shoppingcart.buyProducts"
            title = String(format: fmt.localized(), count, formattedTotal)
            self.checkCheckoutLimits(total)
        } else {
            title = "Snabble.Shoppingcart.buyProducts.now".localized()
        }

        UIView.performWithoutAnimation {
            self.checkoutButton?.setTitle(title, for: .normal)
            self.checkoutButton?.layoutIfNeeded()
        }

        self.checkoutButton?.isHidden = count == 0
    }

    private var notAllMethodsAvailableShown = false
    private var checkoutNotAvailableShown = false

    private func checkCheckoutLimits(_ totalPrice: Int) {
        let formatter = PriceFormatter(SnabbleUI.project)

        if let notAllMethodsAvailable = SnabbleUI.project.checkoutLimits?.notAllMethodsAvailable {
            if totalPrice > notAllMethodsAvailable {
                if !self.notAllMethodsAvailableShown {
                    let limit = formatter.format(notAllMethodsAvailable)
                    self.showLimitAlert(String(format: "Snabble.limitsAlert.notAllMethodsAvailable".localized(), limit))
                    self.notAllMethodsAvailableShown = true
                }
            } else {
                self.notAllMethodsAvailableShown = false
            }
        }

        if let checkoutNotAvailable = SnabbleUI.project.checkoutLimits?.checkoutNotAvailable {
            if totalPrice > checkoutNotAvailable {
                if !self.checkoutNotAvailableShown {
                    let limit = formatter.format(checkoutNotAvailable)
                    self.showLimitAlert(String(format: "Snabble.limitsAlert.checkoutNotAvailable".localized(), limit))
                    self.checkoutNotAvailableShown = true
                }
            } else {
                self.checkoutNotAvailableShown = false
            }
        }
    }

    private func showLimitAlert(_ msg: String) {
        guard self.limitAlert == nil else {
            return
        }

        let alert = UIAlertController(title: "Snabble.limitsAlert.title".localized(), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { action in
            self.limitAlert = nil
        })
        UIApplication.topViewController()?.present(alert, animated: true)
        self.limitAlert = alert
    }
}

extension ShoppingCartViewController: ShoppingCartTableDelegate {

    public func track(_ event: AnalyticsEvent) {
        self.delegate.track(event)
    }

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
        self.updateView(at: row)
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
        if let custom = self.customAppearance {
            cell.setCustomAppearance(custom)
        }
        
        guard indexPath.row < self.items.count else {
            return cell
        }

        let item = self.items[indexPath.row]
        switch item {
        case .cartItem(let item, let lineItems):
            cell.setCartItem(item, lineItems, row: indexPath.row, delegate: self)
        case .lineItem(let item, let lineItems):
            cell.setLineItem(item, lineItems, row: indexPath.row, delegate: self)
        case .discount(let amount):
            cell.setDiscount(amount, delegate: self)
        case .giveaway(let lineItem):
            cell.setGiveaway(lineItem, delegate: self)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteRow(indexPath.row)
        }
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < self.items.count else {
            return false
        }

        let item = self.items[indexPath.row]

        switch item {
        case .cartItem: return true
        case .lineItem: return false
        case .discount: return false
        case .giveaway: return false
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

        self.editButtonItem.isEnabled = false
        self.trashButton.isEnabled = false
    }

    func keyboardWillHide(_ info: KeyboardInfo) {
        guard self.view.window != nil else {
            return
        }

        self.tableBottomMargin.constant = 0
        UIView.animate(withDuration: info.animationDuration) {
            self.view.layoutIfNeeded()
        }

        self.editButtonItem.isEnabled = true
        self.trashButton.isEnabled = true
    }

}

extension ShoppingCartViewController: CustomizableAppearance {
    public func setCustomAppearance(_ appearance: CustomAppearance) {
        self.checkoutButton?.setCustomAppearance(appearance)
        self.customAppearance = appearance

        if let titleIcon = appearance.titleIcon {
            let imgView = UIImageView(image: titleIcon)
            self.navigationItem.titleView = imgView
        }
    }
}
