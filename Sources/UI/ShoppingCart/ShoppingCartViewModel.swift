//
//  ShoppingCartViewModel.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import Foundation
import Combine
import SnabbleCore

open class ShoppingCartViewModel: ObservableObject, Swift.Identifiable, Equatable {
    public let id = UUID()
    
    public static func == (lhs: ShoppingCartViewModel, rhs: ShoppingCartViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    let shoppingCart: ShoppingCart

    weak var shoppingCartDelegate: ShoppingCartDelegate?

    var items = [CartTableEntry]()
    
    @Published var cartItems = [CartItemModel]()
    @Published var updated = false
    
    private var knownImages = Set<String>()
    internal var showImages = false

    var itemCount: Int { items.count }

    func row(for itemModel: CartItemModel) -> Int? {
        guard let index = items.firstIndex(where: { $0.id == itemModel.item.uuid }) else {
            return nil
        }
        return index
    }
    public var formatter: PriceFormatter {
        PriceFormatter(SnabbleCI.project)
    }

    init(shoppingCart: ShoppingCart) {
        self.shoppingCart = shoppingCart

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)

        self.setupItems(self.shoppingCart)
    }
    
    // MARK: notification handlers
    @objc private func shoppingCartUpdated(_ notification: Notification) {
        self.shoppingCart.cancelPendingCheckoutInfoRequest()

        // ignore notifcation sent from this class
        if let object = notification.object as? ShoppingCartViewModel, object == self {
            return
        }

        // if we're on-screen, check for errors from the last checkoutInfo creation/update
        if let error = self.shoppingCart.lastCheckoutInfoError {
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
        self.setupItems(self.shoppingCart)
    }
    
    private func updateQuantity(itemModel: CartItemModel, reload: Bool = true) {
        guard let index = items.firstIndex(where: { $0.id == itemModel.item.uuid }) else {
            return
        }
        guard case .cartItem = self.items[index] else {
            return
        }

//        self.delegate?.track(.cartAmountChanged)

        if reload {
            self.updateQuantity(itemModel.quantity, at: index)
        }
    }
    
    func updateQuantity(_ quantity: Int, at row: Int) {
        guard case .cartItem = self.items[row] else {
            return
        }

        self.shoppingCart.setQuantity(quantity, at: row)
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
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
        
        updateCartItems()
    }
    
    private func updateCartItems() {
        var newItems = [CartItemModel]()
        
        for item in items {
            if case .cartItem(let item, let lineItems) = item {
                let cartItem = CartItemModel(item: item, for: lineItems, showImages: showImages)
                newItems.append(cartItem)
            }
        }
        self.cartItems = newItems
        updated.toggle()
    }
    
    private func delete(itemModel: CartItemModel) {
        guard let index = row(for: itemModel) else {
            return
        }
 
        if case .cartItem = self.items[index] {
//            let product = item.product
//            self.shoppingCartDelegate?.track(.deletedFromCart(product.sku))

            self.items.remove(at: index)
            self.shoppingCart.remove(at: index)
        } else if case .coupon(let coupon, _) = self.items[index] {
            self.items.remove(at: index)
            self.shoppingCart.removeCoupon(coupon.coupon)
        }
        
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.updateView()
    }

    @Published var productError: Bool = false
    @Published var voucherError: Bool = false
    var productErrorMessage: String = ""
    
    private func showProductError(_ skus: [String]) {
        var offendingProducts = [String]()
        for sku in skus {
            if let item = self.shoppingCart.items.first(where: { $0.product.sku == sku }) {
                offendingProducts.append(item.product.name)
            }
        }

        let start = offendingProducts.count == 1 ? Asset.localizedString(forKey: "Snabble.SaleStop.ErrorMsg.one") : Asset.localizedString(forKey: "Snabble.SaleStop.errorMsg")
        let msg = start + "\n\n" + offendingProducts.joined(separator: "\n")
        productErrorMessage = msg
        productError.toggle()
    }

    private func showVoucherError() {
        voucherError.toggle()
    }

    @Published var confirmDeletion: Bool = false
    var deletionMessage: String = ""
    var deletionItem: CartItemModel?
    
    private func confirmDeletion(itemModel: CartItemModel) {
        
        deletionItem = itemModel
        deletionMessage = Asset.localizedString(forKey: "Snabble.Shoppingcart.removeItem", arguments: itemModel.item.product.name)

        confirmDeletion.toggle()
    }

    func cancelDeletion() {
        deletionMessage = ""
        deletionItem = nil
    }

    func processDeletion() {
        guard let item = deletionItem else {
            return
        }
        
        self.delete(itemModel: item)
        
        deletionMessage = ""
        deletionItem = nil
    }
    
    func trash(itemModel: CartItemModel) {
        confirmDeletion(itemModel: itemModel)
    }
    
    func trash(at offset: IndexSet) {
        guard let firstIndex = offset.first else {
            return
        }
        guard cartItems.indices.contains(firstIndex) else {
            return
        }
        trash(itemModel: cartItems[firstIndex])
    }
    
    func decrement(itemModel: CartItemModel) {
        print("- \(itemModel.title)")
        if itemModel.quantity > 1 {
            itemModel.quantity -= 1
            updateQuantity(itemModel: itemModel)
        } else if itemModel.quantity == 1 {
            confirmDeletion(itemModel: itemModel)
        }
    }
    
    func increment(itemModel: CartItemModel) {
        print("+ \(itemModel.title)")
        if itemModel.quantity < ShoppingCart.maxAmount {
            itemModel.quantity += 1
            updateQuantity(itemModel: itemModel)
        }
    }
}

extension ShoppingCartViewModel {
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
            // self.tableView?.reloadData()
        }
    }
}

extension ShoppingCartViewModel {
    func itemsMatchingType<T: ShoppingCartItemPricing>(_ type: T.Type) -> [T] {
      return cartItems.compactMap { $0 as? T }
    }

    var priceItems: [ShoppingCartItemPricing] {
        return itemsMatchingType(CartItemModel.self)
    }
    
    var regularTotal: Int {
        var result: Int = 0
        
        priceItems.forEach { result += $0.regularPrice }
        
        return result
    }
    
    var total: Int {
        var result: Int = 0
        
        priceItems.forEach { result += $0.discountedPrice }
        
        return result
    }
}
extension ShoppingCartViewModel {
    var numberOfProductsString: String {
        return Asset.localizedString(forKey: "Snabble.Shoppingcart.numberOfItems", arguments: self.shoppingCart.numberOfProducts)
    }
}
