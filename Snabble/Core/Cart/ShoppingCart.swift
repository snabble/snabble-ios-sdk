//
//  ShoppingCart.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

/// data needed to initialize a shopping cart
public struct CartConfig {

    /// name of the cart.
    public var name = "default"

    /// directory where the cart should be stored, will be created if it doesn't exist.
    /// Default: the app's "Documents" directory
    public var directory: String

    /// a `ProductProvider` instance to use for resolving SKUs to `Product`s. You must always use the same snabble project for a cart.
    public weak var productProvider: ProductProvider?

    /// url for the "create checkout info" endpoint
    public var checkoutInfoUrl = ""

    /// id of the shop that this cart is used for
    public var shopId = "unknown"

    /// the customer's loyalty card, if known
    public var loyaltyCard: String? = nil

    public init() {
        self.directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
}

/// an entry in a shopping cart. for weighing products, `quantity` is the weight in grams
public struct CartItem: Codable {
    public var quantity: Int
    public let product: Product
    public let scannedCode: String

    init(_ product: Product, quantity: Int, scannedCode: String) {
        self.product = product
        self.quantity = quantity
        self.scannedCode = scannedCode
    }

    var price: Int {
        guard let ean = EAN.parse(self.scannedCode) else {
            return 0
        }

        var price = self.product.priceFor(self.quantity)
        if let embeddedPrice = ean.embeddedPrice {
            price = embeddedPrice
        } else if let embeddedAmount = ean.embeddedAmount {
            price = embeddedAmount * self.product.priceWithDeposit
        }

        return price
    }
}

/// a ShoppingCart is an collection of CartItem objects
public class ShoppingCart {
    
    public static let maxAmount = 9999

    private(set) public var items = [CartItem]()
    var config: CartConfig

    public init(_ config: CartConfig) {
        self.config = config
        self.items = self.loadItems()
    }

    /// get/set this cart's `shopId`
    public var shopId: String {
        get { return self.config.shopId }
        set { self.config.shopId = newValue }
    }

    /// get/set this cart's `loyaltyCard`
    public var loyaltyCard: String? {
        get { return self.config.loyaltyCard }
        set { self.config.loyaltyCard = newValue }
    }

    /// get/set this cart's `createInfoUrl`
    public var checkoutInfoUrl: String {
        get { return self.config.checkoutInfoUrl }
        set { self.config.checkoutInfoUrl = newValue }
    }

    /// add a Product. if already present and not weight dependent, increase its quantity
    ///
    /// the newly added (or modified) product is moved to the start of the list
    public func add(_ product: Product, quantity: Int = 1, scannedCode: String) {
        if let index = self.indexOf(product), product.type == .singleItem {
            var item = self.items[index]
            item.quantity += quantity
            self.items.remove(at: index)
            self.items.insert(item, at: 0)
        } else {
            let item = CartItem(product, quantity: quantity, scannedCode: scannedCode)
            self.items.insert(item, at: 0)
        }

        self.save()
    }

    /// get the `CartItem` at `index`
    public func at(_ index: Int) -> CartItem {
        return self.items[index]
    }

    public func product(at index: Int) -> Product? {
        return self.items[index].product
    }
    
    /// change the quantity of the item at  `index`
    public func setQuantity(_ quantity: Int, at index: Int) {
        self.items[index].quantity = quantity

        self.save()
    }

    /// change the quantity for the given product
    public func setQuantity(_ quantity: Int, for product: Product) {
        if let index = self.indexOf(product) {
            self.setQuantity(quantity, at: index)
        }
    }

    /// delete the entry at position `index`
    public func remove(at index: Int) {
        self.items.remove(at: index)

        self.save()
    }

    /// delete a Product entry if it exists
    public func removeProduct(_ product: Product) {
        if let index = self.indexOf(product) {
            self.remove(at: index)
        }
    }

    /// get the quantity of `product` in the cart.
    public func quantity(of product: Product) -> Int {
        if let index = self.indexOf(product) {
            return self.items[index].quantity
        }
        return 0
    }
    
    /// rearrange order: move the entry at `from` to `to`
    public func moveEntry(from: Int, to: Int) {
        let item = self.items[from]
        self.items.remove(at: from)
        self.items.insert(item, at: to)

        self.save()
    }
    
    /// return the number of separate items
    public var count:  Int {
        return self.items.count
    }

    /// return the the total price of all products
    public var totalPrice: Int {
        return self.items.reduce(0) { $0 + $1.price }
    }
    
    /// return the total number of items
    public func numberOfItems() -> Int {
        var count = 0
        for item in self.items {
            switch item.product.type {
            case .singleItem:
                count += item.quantity
            case .preWeighed, .userMustWeigh:
                count += 1
            }
        }
        return count
    }

    /// get all products from this list
    public func allProducts() -> [Product] {
        return (0 ..< self.items.count).compactMap { self.product(at: $0) }
    }
    
    /// remove all items from the cart
    public func removeAll() {
        self.items.removeAll()
        self.save()
    }

    private func indexOf(_ product: Product) -> Int? {
        return self.items.index { $0.product.sku == product.sku }
    }
}

// MARK: - Persistence
extension ShoppingCart {

    private func cartUrl() -> URL {
        let path = self.config.directory + "/" + self.config.name + ".json"
        return URL(fileURLWithPath: path)
    }

    /// persist this shopping cart to disk
    private func save() {
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: self.config.directory) {
                try fileManager.createDirectory(atPath: self.config.directory, withIntermediateDirectories: true, attributes: nil)
            }

            let encodedItems = try JSONEncoder().encode(self.items)
            try encodedItems.write(to: self.cartUrl(), options: .atomic)
        } catch let error {
            NSLog("error saving cart \(self.config.name): \(error)")
        }
    }

    // load this shoppping cart from disk
    private func loadItems() -> [CartItem] {
        do {
            let data = try Data(contentsOf: self.cartUrl())
            let items = try JSONDecoder().decode([CartItem].self, from: data)
            return items.map { CartItem(self.refreshLocal($0.product), quantity: $0.quantity, scannedCode: $0.scannedCode) }
        } catch let error {
            NSLog("error loading cart \(self.config.name): \(error)")
            return []
        }
    }

    private func refreshLocal(_ product: Product) -> Product {
        if let p = self.config.productProvider?.productBySku(product.sku) {
            return p
        } else {
            return product
        }
    }

}



