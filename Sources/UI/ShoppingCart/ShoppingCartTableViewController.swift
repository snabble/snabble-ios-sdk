//
//  ShoppingCartTableViewController.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

// the "real" shoppingcart table
// used as a child view controller in both the standalone ShoppingCartViewController and
// in the ScannerDrawerViewController

import UIKit
import SnabbleCore

enum CartTableEntry: Swift.Identifiable {
    var id: String {
        switch self {
        case .cartItem(let cartItem, _):
            return cartItem.uuid
            
        case .coupon(let cartCoupon, _):
            return cartCoupon.uuid
            
            // stuff we get from the backend isn't
        case .lineItem(let lineItem, _):
            return lineItem.id
            
        case .discount(let discount):
            return String(discount)
            
        case .giveaway(let lineItem):
            return lineItem.id
        }
    }
    
    // our main item and any additional line items referring to it
    case cartItem(CartItem, [CheckoutInfo.LineItem])

    // a user-added coupon, plus the backend info for it
    case coupon(CartCoupon, CheckoutInfo.LineItem?)

    // a new main item from the backend, plus its additional items.
    case lineItem(CheckoutInfo.LineItem, [CheckoutInfo.LineItem])

    // a giveaway
    case giveaway(CheckoutInfo.LineItem)

    // sums up the total discounts
    case discount(Int)
    
    var canEdit: Bool {
        switch self {
            // user stuff is editable
        case .cartItem: return true
        case .coupon: return true
            // stuff we get from the backend isn't
        case .lineItem: return false
        case .discount: return false
        case .giveaway: return false
        }
    }
    static func rowFor(item: CartItem, in array: [CartTableEntry]) -> Int? {
        return array.firstIndex(where: { $0.id == item.uuid })
    }
}

final class ShoppingCartTableViewController: UITableViewController {
    private var customAppearance: CustomAppearance?

    private let itemCellIdentifier = "itemCell"

    var insets: UIEdgeInsets = .zero {
        didSet {
            tableView?.contentInset = insets
            tableView?.scrollIndicatorInsets = insets
        }
    }

    var shoppingCart: ShoppingCart! {
        didSet {
            self.setupItems(self.shoppingCart)
            self.tableView?.reloadData()
        }
    }

    weak var shoppingCartDelegate: ShoppingCartDelegate?

    private var items = [CartTableEntry]()

    private var knownImages = Set<String>()
    internal var showImages = false

    var itemCount: Int { items.count }

    init(_ cart: ShoppingCart) {
        super.init(style: .plain)

        self.view.backgroundColor = .systemBackground

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)

        self.shoppingCart = cart

        SnabbleCI.registerForAppearanceChange(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15, *) {
            self.view.restrictDynamicTypeSize(from: nil, to: .extraExtraExtraLarge)
        }

        self.view.backgroundColor = .clear

        self.tableView.register(ShoppingCartTableCell.self, forCellReuseIdentifier: self.itemCellIdentifier)

        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.backgroundColor = .clear

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 50
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateView()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.shoppingCartDelegate?.track(.viewShoppingCart)
    }

    // MARK: notification handlers
    @objc private func shoppingCartUpdated(_ notification: Notification) {
        self.shoppingCart.cancelPendingCheckoutInfoRequest()

        // ignore notifcation sent from this class
        if let object = notification.object as? ShoppingCartTableViewController, object == self {
            return
        }

        // if we're on-screen, check for errors from the last checkoutInfo creation/update
        if self.view.window != nil, let error = self.shoppingCart.lastCheckoutInfoError {
            switch error.type {
            case .saleStop:
                if let offendingSkus = error.details?.compactMap({ $0.sku }) {
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
            let task = Snabble.urlSession.dataTask(with: url) { _, _, _ in }
            task.resume()
        }
        self.knownImages = images
    }

    func deleteCart() {
        self.shoppingCartDelegate?.track(.deletedEntireCart)
        self.shoppingCart.removeAll(endSession: false, keepBackup: false)
        self.updateView()
    }

    func updateView(at row: Int? = nil) {
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

        // avoid ugly visual glitch
        if self.items.isEmpty && self.isEditing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setEditing(false, animated: false)
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
                    let productProvider = Snabble.shared.productProvider(for: SnabbleCI.project)
                    let product = productProvider.productBy(sku: sku, shopId: self.shoppingCart.shopId)
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

        for coupon in cart.coupons {
            if let lineItems = cart.backendCartInfo?.lineItems {
                let couponItem = lineItems.filter { $0.couponID == coupon.coupon.id }.first
                let item = CartTableEntry.coupon(coupon, couponItem)
                self.items.append(item)
            } else {
                let item = CartTableEntry.coupon(coupon, nil)
                self.items.append(item)
            }
        }

        // perform any pending lookups
        if !pendingLookups.isEmpty {
            self.performPendingLookups(pendingLookups, self.shoppingCart.lastSaved)
        }

        // now gather the remaining lineItems. find the main items first
        if let lineItems = cart.backendCartInfo?.lineItems {
            let cartIds = Set(cart.items.map { $0.uuid })

            let mainItems = lineItems.filter { $0.type == .default && !cartIds.contains($0.id) }

            for item in mainItems {
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

        // add all discounts and priceModifiers for the "total discounts" entry
        if let lineItems = cart.backendCartInfo?.lineItems {
            var totalDiscounts = 0
            let discounts = lineItems.filter { $0.type == .discount }
            totalDiscounts = discounts.reduce(0) { $0 + $1.amount * ($1.price ?? 0) }

            for lineItem in lineItems {
                guard let modifiers = lineItem.priceModifiers else { continue }
                let modSum = modifiers.reduce(0, { $0 + $1.price })
                totalDiscounts += modSum * lineItem.amount
            }

            if totalDiscounts != 0 {
                let item = CartTableEntry.discount(totalDiscounts)
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

        let start = offendingProducts.count == 1 ? Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.one") : Asset.localizedString(forKey: "Snabble.SaleStop.errorMsg")
        let msg = start + "\n\n" + offendingProducts.joined(separator: "\n")
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.title"), message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    private func showVoucherError() {
        let alert = UIAlertController(title: Asset.localizedString(forKey: "Snabble.InvalidDepositVoucher.errorMsg"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.ok"), style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

extension ShoppingCartTableViewController: ShoppingCartTableDelegate {
    public func track(_ event: AnalyticsEvent) {
        self.shoppingCartDelegate?.track(event)
    }

    func confirmDeletion(at row: Int) {
        guard case .cartItem(let item, _) = self.items[row] else {
            return
        }

        let product = item.product
        let quantity = item.quantity
        
        let msg = Asset.localizedString(forKey: "Snabble.Shoppingcart.removeItem", arguments: product.name)
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.yes"), style: .destructive) { _ in
            self.deleteRow(row)
        })

        alert.addAction(UIAlertAction(title: Asset.localizedString(forKey: "Snabble.no"), style: .cancel) { _ in
            self.shoppingCart.setQuantity(quantity, at: row)
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

    func makeRowVisible(row: Int) {
        self.pulleyViewController?.setDrawerPosition(position: .open, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ShoppingCartTableViewController {
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = self.items.count
        return rows
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: self.itemCellIdentifier, for: indexPath) as! ShoppingCartTableCell
        if let custom = self.customAppearance {
            cell.setCustomAppearance(custom)
        }

        guard indexPath.row < self.items.count else {
            return cell
        }
        cell.configureCell(row: indexPath.row, delegate: self)
        let item = self.items[indexPath.row]
        switch item {
        case .cartItem(let item, let lineItems):
            cell.setCartItem(item, for: lineItems)
        case .coupon(let coupon, let lineItem):
            cell.setCouponItem(coupon, for: lineItem)

        case .lineItem(let item, let lineItems):
            cell.setLineItem(item, for: lineItems)
        case .discount(let amount):
            cell.setDiscount(for: amount)
        case .giveaway(let lineItem):
            cell.setGiveaway(for: lineItem)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteRow(indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < self.items.count else {
            return false
        }

        let item = self.items[indexPath.row]
        return item.canEdit
    }

    // call tableView.deleteRows(at:) inside a CATransaction block so that we can reload the tableview afterwards
    private func deleteRow(_ row: Int) {
        guard row < self.items.count else {
            return
        }

        if case .cartItem(let item, _) = self.items[row] {
            let product = item.product
            self.shoppingCartDelegate?.track(.deletedFromCart(product.sku))

            self.items.remove(at: row)
            self.shoppingCart.remove(at: row)
        } else if case .coupon(let coupon, _) = self.items[row] {
            self.items.remove(at: row)
            self.shoppingCart.removeCoupon(coupon.coupon)
        }

        let indexPath = IndexPath(row: row, section: 0)
        CATransaction.begin()
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: [indexPath], with: .none)
        self.tableView.endUpdates()

        CATransaction.setCompletionBlock {
            NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
            self.updateView()
        }

        CATransaction.commit()
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return Asset.localizedString(forKey: "Snabble.remove")
    }
}

// MARK: - appearance
extension ShoppingCartTableViewController: CustomizableAppearance {
    func setCustomAppearance(_ appearance: CustomAppearance) {
        self.customAppearance = appearance
    }
}

extension ShoppingCartTableViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let appearance = self.customAppearance {
            self.setCustomAppearance(appearance)
        }
    }
}

// MARK: - pending lookups

extension ShoppingCartTableViewController {
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

        let productProvider = Snabble.shared.productProvider(for: SnabbleCI.project)
        for lookup in lookups {
            guard let sku = lookup.lineItem.sku else {
                continue
            }

            group.enter()

            productProvider.productBy(sku: sku, shopId: self.shoppingCart.shopId) { result in
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
