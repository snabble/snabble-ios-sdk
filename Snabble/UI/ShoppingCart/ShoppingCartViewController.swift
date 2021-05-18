//
//  ShoppingCartViewController.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit

enum CartTableEntry {
    // our main item and any additional line items referring to it
    case cartItem(CartItem, [CheckoutInfo.LineItem])

    // a new main item from the backend, plus its additional items.
    case lineItem(CheckoutInfo.LineItem, [CheckoutInfo.LineItem])

    // a giveaway
    case giveaway(CheckoutInfo.LineItem)

    // sums up the total discounts
    case discount(Int)
}

final class ShoppingCartViewController: UITableViewController {
    private var limitAlert: UIAlertController?
    private var customAppearance: CustomAppearance?

    private let itemCellIdentifier = "itemCell"

    var shoppingCart: ShoppingCart! {
        didSet {
            self.setupItems(self.shoppingCart)
            self.tableView?.reloadData()
        }
    }

    private weak var delegate: ShoppingCartDelegate?

    private var items = [CartTableEntry]()

    private var knownImages = Set<String>()
    internal var showImages = false

    init(_ cart: ShoppingCart, delegate: ShoppingCartDelegate) {
        super.init(style: .plain)

        self.delegate = delegate

        self.title = "Snabble.ShoppingCart.title".localized()
        self.tabBarItem.image = UIImage.fromBundle(cart.numberOfProducts == 0 ? "SnabbleSDK/icon-cart-inactive-empty" : "SnabbleSDK/icon-cart-inactive-full")
        self.tabBarItem.selectedImage = UIImage.fromBundle("SnabbleSDK/icon-cart-active")

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)

        self.shoppingCart = cart

        SnabbleUI.registerForAppearanceChange(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground

        self.tableView.register(UINib(nibName: "ShoppingCartTableCell", bundle: SnabbleBundle.main), forCellReuseIdentifier: self.itemCellIdentifier)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 78
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.delegate?.track(.viewShoppingCart)

        if !self.isBeingPresented && !self.isMovingToParent {
            // whatever was covering us has been dismissed or popped

            // re-send our current cart to the backend so that the supervisor can see us shopping again
            CartEvent.cart(self.shoppingCart)
        }
    }

    // MARK: notification handlers
    @objc private func shoppingCartUpdated(_ notification: Notification) {
        self.shoppingCart.cancelPendingCheckoutInfoRequest()

        // ignore notifcation sent from this class
        if let object = notification.object as? ShoppingCartViewController, object == self {
            return
        }

        // if we're on-screen, check for errors from the last checkoutInfo creation/update
        if self.view.window != nil, let error = self.shoppingCart.lastCheckoutInfoError {
            switch error.error.type {
            case .saleStop:
                if let offendingSkus = error.error.details?.compactMap({ $0.sku }) {
                    self.showProductError(offendingSkus)
                }
            case .invalidDepositVoucher:
                self.showVoucherError()
            default:
                ()
            }
        }

        self.setupItems(self.shoppingCart)
        self.tableView?.reloadData()

        self.getMissingImages()
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
            let task = URLSession.shared.dataTask(with: url) { _, _, _ in }
            task.resume()
        }
        self.knownImages = images
    }

    func showDeleteCartAlert() {
        let alert = UIAlertController(title: "Snabble.Shoppingcart.removeItems".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { _ in
            self.deleteCart()
        })
        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }

    func deleteCart() {
        self.delegate?.track(.deletedEntireCart)
        self.shoppingCart.removeAll()
        self.updateView()
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
                if !self.items.isEmpty {
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func setupItems(_ cart: ShoppingCart) {
        self.items = []

        var pendingLookups = [PendingLookup]()

        // find all line items that refer to our own cart items
        for (index, cartItem) in cart.items.enumerated() {
            if let lineItems = cart.backendCartInfo?.lineItems {
                let items = lineItems.filter { $0.id == cartItem.uuid || $0.refersTo == cartItem.uuid }

                // if we have a single lineItem that updates this entry with another SKU,
                // propagate the change to the shopping cart
                if let lineItem = items.first, items.count == 1, let sku = lineItem.sku, sku != cartItem.product.sku {
                    let provider = SnabbleAPI.productProvider(for: SnabbleUI.project)
                    let product = provider.productBySku(sku, self.shoppingCart.shopId)
                    if let product = product, let replacement = CartItem(replacing: cartItem, product, self.shoppingCart.shopId, lineItem) {
                        cart.replaceItem(at: index, with: replacement)
                    } else {
                        pendingLookups.append(PendingLookup(index, cartItem, lineItem))
                    }
                }
                let item = CartTableEntry.cartItem(cartItem, items)
                self.items.append(item)
            } else {
                let item = CartTableEntry.cartItem(cartItem, [])
                self.items.append(item)
            }
        }

        // perform any pending lookups
        if !pendingLookups.isEmpty {
            self.performPendingLookups(pendingLookups, self.shoppingCart.lastSaved)
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
            if !discounts.isEmpty {
                let sum = discounts.reduce(0) { $0 + $1.amount * ($1.price ?? 0) }
                let item = CartTableEntry.discount(sum)
                self.items.append(item)
            }
        }

        // check if any of the cart items's products has an associated image
        let imgIndex = cart.items.firstIndex { $0.product.imageUrl != nil }
        self.showImages = imgIndex != nil
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

    private func showVoucherError() {
        let alert = UIAlertController(title: "Snabble.invalidDepositVoucher.errorMsg".localized(), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default, handler: nil))
        self.present(alert, animated: true)
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
        alert.addAction(UIAlertAction(title: "Snabble.OK".localized(), style: .default) { _ in
            self.limitAlert = nil
        })
        UIApplication.topViewController()?.present(alert, animated: true)
        self.limitAlert = alert
    }
}

extension ShoppingCartViewController: ShoppingCartTableDelegate {

    func track(_ event: AnalyticsEvent) {
        self.delegate?.track(event)
    }

    func confirmDeletion(at row: Int) {
        guard case .cartItem(let item, _) = self.items[row] else {
            return
        }

        let product = item.product

        let msg = String(format: "Snabble.Shoppingcart.removeItem".localized(), product.name)
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Snabble.Yes".localized(), style: .destructive) { _ in
            self.deleteRow(row)
        })

        alert.addAction(UIAlertAction(title: "Snabble.No".localized(), style: .cancel) { _ in
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
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.updateView(at: row)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ShoppingCartViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = self.items.count
        return rows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
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

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteRow(indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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

    // call tableView.deleteRows(at:) inside a CATransaction block so that we can reload the tableview afterwards
    func deleteRow(_ row: Int) {
        guard row < self.items.count, case .cartItem(let item, _) = self.items[row] else {
            return
        }

        let product = item.product
        self.delegate?.track(.deletedFromCart(product.sku))

        self.items.remove(at: row)

        let indexPath = IndexPath(row: row, section: 0)
        CATransaction.begin()
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()

        CATransaction.setCompletionBlock {
            self.shoppingCart.remove(at: row)
            NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
            self.updateView()
        }

        CATransaction.commit()
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Snabble.remove".localized()
    }
}

// MARK: - appearance
extension ShoppingCartViewController: CustomizableAppearance {
    func setCustomAppearance(_ appearance: CustomAppearance) {
        self.customAppearance = appearance

        SnabbleUI.getAsset(.storeLogoSmall) { img in
            if let image = img ?? appearance.titleIcon {
                let imgView = UIImageView(image: image)
                self.navigationItem.titleView = imgView
            }
        }
    }
}

extension ShoppingCartViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let appearance = self.customAppearance {
            self.setCustomAppearance(appearance)
        }
    }
}

// MARK: - pending lookups

extension ShoppingCartViewController {
    private struct PendingLookup {
        let index: Int
        let cartItem: CartItem
        let lineItem: CheckoutInfo.LineItem

        init(_ index: Int, _ cartItem: CartItem, _ lineItem: CheckoutInfo.LineItem) {
            self.index = index
            self.cartItem = cartItem
            self.lineItem = lineItem
        }
    }

    private func performPendingLookups(_ lookups: [PendingLookup], _ lastSaved: Date?) {
        let group = DispatchGroup()

        var replacements = [(Int, CartItem?)]()
        let mutex = Mutex()

        let provider = SnabbleAPI.productProvider(for: SnabbleUI.project)
        for lookup in lookups {
            guard let sku = lookup.lineItem.sku else {
                continue
            }

            group.enter()

            provider.productBySku(sku, self.shoppingCart.shopId) { result in
                switch result {
                case .failure(let error):
                    Log.error("error in pending lookup for \(sku): \(error)")
                case .success(let product):
                    let replacement = CartItem(replacing: lookup.cartItem, product, self.shoppingCart.shopId, lookup.lineItem)
                    mutex.lock()
                    replacements.append((lookup.index, replacement))
                    mutex.unlock()
                }
                group.leave()
            }
        }

        // when all lookups are finished:
        group.notify(queue: DispatchQueue.main) {
            guard !replacements.isEmpty, self.shoppingCart.lastSaved == lastSaved else {
                Log.warn("no replacements, or cart was modified during retrieval")
                return
            }

            for (index, item) in replacements {
                if let item = item {
                    self.shoppingCart.replaceItem(at: index, with: item)
                } else {
                    Log.warn("no replacement for item #\(index) found")
                }
            }
            self.tableView?.reloadData()
        }
    }
}
