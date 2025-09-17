//
//  ShoppingCartViewModel.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import Foundation
import Combine
import SnabbleCore
import SnabbleAssetProviding

public extension ShoppingCart {
    static let textFieldMagic: Int = 0x4711
}

open class ShoppingCartViewModel: ObservableObject, Swift.Identifiable, Equatable {
    public let id = UUID()
    
    public static func == (lhs: ShoppingCartViewModel, rhs: ShoppingCartViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    public var formatter: PriceFormatter {
        PriceFormatter(SnabbleCI.project)
    }
    
    public let shoppingCart: ShoppingCart
    
    public weak var shoppingCartDelegate: ShoppingCartDelegate?
    
    @Published public var productError: Bool = false
    var productErrorMessage: String = ""
    
    @Published public var confirmDeletion: Bool = false
    var deletionMessage: String = ""
    var deletionItemIndex: Int?
    
    @Published public var items = [CartEntry]()
    
    func index(for itemModel: CartItemModel) -> Int? {
        guard let index = items.firstIndex(where: { $0.id == itemModel.id }) else {
            return nil
        }
        return index
    }
    
    func index(for item: CartEntry) -> Int? {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return nil
        }
        return index
    }

    private var knownImages = Set<String>()
    internal var showImages = false
    
    public init(shoppingCart: ShoppingCart) {
        self.shoppingCart = shoppingCart
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)
        
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
            default:
                break
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
    
    func updateView(at row: Int? = nil) {
        self.setupItems(self.shoppingCart)
    }
    
    private func setupItems(_ cart: ShoppingCart) {
        var newItems = [CartEntry]()
        
        // all regular cart items
        newItems.append(contentsOf: self.cartItemEntries)
        // all coupons
        newItems.append(contentsOf: self.couponItems)
        // now gather the remaining lineItems. find the main items first
        newItems.append(contentsOf: self.remainingItems)

        // all vouchers
        newItems.append(contentsOf: self.voucherItems)

        // add all discounts (without priceModifiers) for the "total discounts" entry
        if cart.totalCartDiscount != 0 {
            newItems.append(totalDiscountItem)
        }
        
        let pendingLookups = self.pendingLookups
        // perform any pending lookups
        if !pendingLookups.isEmpty {
            self.performPendingLookups(pendingLookups, self.shoppingCart.lastSaved)
        }
        
        // check if any of the cart items's products has an associated image
        let imgIndex = cart.items.firstIndex { $0.product.imageUrl != nil }
        self.showImages = imgIndex != nil
        
        self.items = newItems
    }
}

extension ShoppingCartViewModel {
    func cartIndex(for itemModel: ProductItemModel) -> Int? {
        guard let index = items.firstIndex(where: { $0.id == itemModel.item.uuid }) else {
            return nil
        }
        guard case .cartItem = self.items[index] else {
            return nil
        }
        return index
    }
    
    private func updateQuantity(itemModel: ProductItemModel, reload: Bool = true) {
        guard cartIndex(for: itemModel) != nil else {
            return
        }
        
        self.shoppingCartDelegate?.track(.cartAmountChanged)
        
        if reload {
            self.shoppingCart.setQuantity(itemModel.quantity, for: itemModel.item)
            NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        }
    }
    
    func updateQuantity(_ quantity: Int, at row: Int) {
        guard case .cartItem = self.items[row] else {
            return
        }
        
        self.shoppingCart.setQuantity(quantity, at: row)
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
    }
}

extension ShoppingCartViewModel {
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
}

extension ShoppingCartViewModel {
    func deleteCart() {
        self.shoppingCartDelegate?.track(.deletedEntireCart)
        self.shoppingCart.removeAll(endSession: false, keepBackup: false)
        self.updateView()
    }
    
    private func delete(at index: Int) {
        if case .cartItem(let item, _) = self.items[index] {

            self.shoppingCartDelegate?.track(.deletedFromCart(item.product.sku))
            
            self.items.remove(at: index)
            self.shoppingCart.removeItem(item)
        } else if case .coupon(let coupon, _) = self.items[index] {
            self.items.remove(at: index)
            self.shoppingCart.removeCoupon(coupon.coupon)
        } else if case .voucher(let voucherItem, _) = self.items[index] {
            self.items.remove(at: index)
            self.shoppingCart.removeVoucher(voucherItem.voucher)
        }
        
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.updateView()
    }
    
    private func delete(itemModel: CartItemModel) {
        guard let index = index(for: itemModel) else {
            return
        }
        delete(at: index)
    }

    public func delete(item: CartEntry) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        delete(at: index)
    }

    private func confirmDeletion(at index: Int) {
        var name: String?
        
        if case .cartItem(let item, _) = self.items[index] {
            name = item.product.name
        } else if case .coupon(let cartCoupon, _) = self.items[index] {
            name = cartCoupon.coupon.name
        } else if case .voucher(let cartVoucher, _) = self.items[index] {
            name = cartVoucher.voucher.name
        }
        guard let name = name else {
            return
        }
        deletionItemIndex = index
        deletionMessage = Asset.localizedString(forKey: "Snabble.Shoppingcart.removeItem", arguments: name)
        
        confirmDeletion.toggle()
    }
    
    private func confirmDeletion(itemModel: CartItemModel) {
        guard let index = index(for: itemModel) else {
            return
        }
        confirmDeletion(at: index)
    }
    
    private func confirmDeletion(item: CartEntry) {
        guard let index = index(for: item) else {
            return
        }
        confirmDeletion(at: index)
    }

    func cancelDeletion() {
        deletionMessage = ""
        deletionItemIndex = nil
    }
    
    func processDeletion() {
        guard let index = deletionItemIndex else {
            return
        }
        
        self.delete(at: index)
        
        deletionMessage = ""
        deletionItemIndex = nil
    }
}

extension ShoppingCartViewModel {

    func trash(item: CartEntry) {
        confirmDeletion(item: item)
    }

    func trash(itemModel: CartItemModel) {
        confirmDeletion(itemModel: itemModel)
    }

    func trash(at offset: IndexSet) {
        let index = offset[offset.startIndex]
        confirmDeletion(at: index)
    }
    
    func decrement(itemModel: ProductItemModel) {
        print("- \(itemModel.title)")
        if itemModel.quantity > 1 {
            itemModel.quantity -= 1
            updateQuantity(itemModel: itemModel)
        } else if itemModel.quantity == 1 {
            confirmDeletion(itemModel: itemModel)
        }
    }
    
    func increment(itemModel: ProductItemModel) {
        print("+ \(itemModel.title)")
        if itemModel.quantity < ShoppingCart.maxAmount {
            itemModel.quantity += 1
            updateQuantity(itemModel: itemModel)
        }
    }
}

extension ShoppingCartViewModel {
    func discountItems(item: CartItem, for lineItems: [CheckoutInfo.LineItem]) -> [ShoppingCartItemDiscount] {

        var discountItems = [ShoppingCartItemDiscount]()
        
        for lineItem in lineItems {
            guard let modifiers = lineItem.priceModifiers else { continue }
            
            for modifier in modifiers {
                let discount = item.discountedPrice(withModifier: modifier, for: lineItem)
                let discountCartItem = ShoppingCartItemDiscount(discount: discount, name: modifier.name, type: .priceModifier)
                discountItems.append(discountCartItem)
            }
        }
        
        let discounts = lineItems.filter { $0.type == .discount }
        let cartDiscountID = shoppingCart.cartDiscountLineItems?.first?.discountID
        
        for discount in discounts {
            if cartDiscountID == nil, let total = discount.totalPrice {
                let discountCartItem = ShoppingCartItemDiscount(discount: total, name: discount.name, type: .discountedProduct)
                discountItems.append(discountCartItem)
            } else if discount.discountID != cartDiscountID, let total = discount.totalPrice {
                let discountCartItem = ShoppingCartItemDiscount(discount: total, name: discount.name, type: .discountedProduct)
                discountItems.append(discountCartItem)
            }
        }
        return discountItems
    }
    
    var totalDiscountItem: CartEntry {
        return CartEntry.discount(totalDiscount)
    }

    var totalDiscount: Int {
        return self.shoppingCart.totalCartDiscount
    }
    
    var totalDiscountDescription: String? {
        return self.shoppingCart.cartDiscountDescription
    }
    
    var totalDiscountString: String {
        formatter.format(totalDiscount)
    }
}

extension ShoppingCartViewModel {
    var cartItemEntries: [CartEntry] {
        var items = [CartEntry]()
        
        for cartItem in cartItems {
            let item = CartEntry.cartItem(cartItem.cartItem, cartItem.lineItems)
            items.append(item)
        }
        return items
    }

    var cartItems: [(cartItem: CartItem, lineItems: [CheckoutInfo.LineItem])] {
        return internalCartItems.cartItems
    }

    // find all line items that refer to our own cart items
    private var internalCartItems: (cartItems: [(cartItem: CartItem, lineItems: [CheckoutInfo.LineItem])], pendingLookups: [PendingLookup]) {
        var cartItems = [(cartItem: CartItem, lineItems: [CheckoutInfo.LineItem])]()
        var pendingLookups = [PendingLookup]()

        // find all line items that refer to our own cart items
        for (index, cartItem) in self.shoppingCart.items.enumerated() {
            if let lineItems = self.shoppingCart.backendCartInfo?.lineItems {
                let items = lineItems.filter { $0.id == cartItem.uuid || $0.refersTo == cartItem.uuid }

                // if we have a single lineItem that updates this entry with another SKU,
                // propagate the change to the shopping cart
                if let lineItem = items.first, items.count == 1, let sku = lineItem.sku, sku != cartItem.product.sku {
                    let productProvider = Snabble.shared.productProvider(for: SnabbleCI.project)
                    let product = productProvider.productBy(sku: sku, shopId: self.shoppingCart.shopId)
                    if let product = product, let replacement = CartItem(replacing: cartItem, product, self.shoppingCart.shopId, lineItem) {
                        self.shoppingCart.replaceItem(at: index, with: replacement)
                    } else {
                        pendingLookups.append(PendingLookup(index, cartItem, lineItem))
                    }
                }
                cartItems.append((cartItem, items))
            } else {
                cartItems.append((cartItem, []))
            }
        }
        return (cartItems, pendingLookups)
    }

    private var pendingLookups: [PendingLookup] {
        return internalCartItems.pendingLookups
    }
}

extension ShoppingCartViewModel {
    var couponItems: [CartEntry] {
        var items = [CartEntry]()
        
        // all coupons
        for coupon in self.coupons {
            let item = CartEntry.coupon(coupon.cartCoupon, coupon.lineItem)
            items.append(item)
        }
        return items
    }
    
    // all coupons
    var coupons: [(cartCoupon: CartCoupon, lineItem: CheckoutInfo.LineItem?)] {
        var coupons = [(cartCoupon: CartCoupon, lineItem: CheckoutInfo.LineItem?)]()

        for coupon in self.shoppingCart.coupons {
            let couponItem = self.shoppingCart.backendCartInfo?.lineItems.filter { $0.couponID == coupon.coupon.id }.first

            coupons.append((coupon, couponItem))
        }
        return coupons
    }
}

extension ShoppingCartViewModel {
    var voucherItems: [CartEntry] {
        self.shoppingCart.voucherItems
    }
}

extension ShoppingCartViewModel {
    // the remaining lineItems
    var remainingItems: [CartEntry] {
        var items = [CartEntry]()
        for lineItem in remainingLineItems {
            let item = CartEntry.lineItem(lineItem.lineItem, lineItem.additionalItems)
            items.append(item)
        }
        return items
    }

    var remainingLineItems: [(lineItem: CheckoutInfo.LineItem, additionalItems: [CheckoutInfo.LineItem])] {
        var items = [(lineItem: CheckoutInfo.LineItem, additionalItems: [CheckoutInfo.LineItem])]()
        
        // now gather the remaining lineItems. find the main items first
        if let lineItems = self.shoppingCart.backendCartInfo?.lineItems {
            let cartIds = Set(self.shoppingCart.items.map { $0.uuid })

            let mainItems = lineItems.filter { $0.type == .default && !cartIds.contains($0.id) }

            for item in mainItems {
                let additionalItems = lineItems.filter { $0.type != .default && $0.refersTo == item.id }
                items.append((item, additionalItems))
            }
        }
        return items
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
        }
    }
}

extension ShoppingCartViewModel {    

    var regularTotal: Int? {
        guard let total = shoppingCart.total else {
            return nil
        }
        return total
    }

    var regularTotalString: String {
        guard let regularTotal = regularTotal else {
            return ""
        }
        return formatter.format(regularTotal)
    }

    var total: Int? {
        let cartTotal = SnabbleCI.project.displayNetPrice ? shoppingCart.backendCartInfo?.netPrice : shoppingCart.backendCartInfo?.totalPrice

        return cartTotal ?? shoppingCart.total
    }

    var totalString: String {
        guard let total = total else {
            return ""
        }
        return formatter.format(total)
    }
}

extension ShoppingCartViewModel {
    
    var cartIsEmpty: Bool {
        self.numberOfItems == 0
    }

    /// numberOfItems in shoppingCart = numberOfProducts (shoppingCart.items.count) + numberOfVouchers (shoppingCart.vouchers.count)
    var numberOfItems: Int {
        self.shoppingCart.numberOfItems
    }
    
    var numberOfProducts: Int {
        self.shoppingCart.numberOfProducts
    }

    var numberOfProductsString: String {
        Asset.localizedString(forKey: "Snabble.Shoppingcart.numberOfItems", arguments: self.numberOfItems)
    }
}
