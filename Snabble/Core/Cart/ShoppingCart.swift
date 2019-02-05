//
//  ShoppingCart.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

/// data needed to initialize a shopping cart
public struct CartConfig {

    /// directory where the cart should be stored, will be created if it doesn't exist.
    /// Default: the app's "Documents" directory
    public var directory: String

    /// the `Project` that this cart is used in. You must always use the same snabble project for a cart.
    public var project = Project.none

    /// the shop that this cart is used for
    public var shop = Shop.none

    /// the customer's loyalty card, if known
    public var loyaltyCard: String? = nil

    /// the maximum age of a shopping cart, in seconds. Set this to 0 to keep carts forever
    public var maxAge: TimeInterval = 14400

    public init() {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.directory = docDir.path
    }
}

/// an entry in a shopping cart.
public struct CartItem: Codable {
    public var quantity: Int
    public let product: Product
    public let scannedCode: String

    /// for shelf codes that have 0 as the embedded units and need to be editable later
    public let editableUnits: Bool

    // optional data extracted from the scanned code
    public let embeddedData: Int?
    // what does the embedded data represent?
    public let encodingUnit: Units?
    // optional reference price
    public let referencePrice: Int?

    init(_ quantity: Int, _ product: Product, _ scannedCode: String, _ embeddedData: Int? = nil, _ editableUnits: Bool = false, _ encodingUnit: Units? = nil, _ referencePrice: Int? = nil) {
        self.product = product
        self.quantity = quantity
        self.editableUnits = editableUnits
        self.scannedCode = scannedCode
        self.embeddedData = embeddedData
        self.encodingUnit = encodingUnit
        self.referencePrice = referencePrice
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.product = try container.decode(Product.self, forKey: .product)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.scannedCode = try container.decode(String.self, forKey: .scannedCode)
        self.editableUnits = try container.decodeIfPresent(Bool.self, forKey: .editableUnits) ?? false
        self.embeddedData = try container.decodeIfPresent(Int.self, forKey: .embeddedData)
        self.encodingUnit = try container.decodeIfPresent(Units.self, forKey: .encodingUnit)
        self.referencePrice = try container.decodeIfPresent(Int.self, forKey: .referencePrice)
    }

    // init with a freshly retrieved copy of `item.product`.
    init?(updating item: CartItem, _ provider: ProductProvider, _ shopId: String) {
        guard let product = provider.productBySku(item.product.sku, shopId) else {
            return nil
        }

        self.product = product
        self.quantity = item.quantity
        self.scannedCode = item.scannedCode
        self.editableUnits = item.editableUnits
        self.embeddedData = item.embeddedData
        self.encodingUnit = item.encodingUnit
        self.referencePrice = item.referencePrice
    }

    /// total price for this cart item
    public func total(_ project: Project) -> Int {
        return self.price(for: self.quantity, project)
    }

    /// item price
    public func itemPrice(_ project: Project) -> Int {
        return self.price(for: 1, project)
    }

    func price(for quantity: Int, _ project: Project) -> Int {
        let unit = self.product.encodingUnit ?? self.encodingUnit
        guard let embed = self.embeddedData, let encodingUnit = unit else {
            return PriceFormatter.priceFor(project, self.product, quantity)
        }

        switch encodingUnit {
        case .price:
            return embed
        case .piece:
            let multiplier = embed == 0 ? self.quantity : embed
            return multiplier * self.product.price
        default:
            return PriceFormatter.priceFor(project, self.product, embed, self.encodingUnit, self.referencePrice)
        }
    }

    func cartItem() -> Cart.Item {
        let product = self.product
        var quantity = self.quantity
        
        var price: Int? = nil
        var weight: Int? = nil
        var units: Int? = nil

        if product.type == .userMustWeigh {
            quantity = 1
            weight = self.quantity
        } else if product.referenceUnit == .piece && (self.embeddedData == nil || self.embeddedData == 0) {
            quantity = 1
            units = self.quantity
        } else if let embed = self.embeddedData, let encodingUnit = self.encodingUnit {
            switch encodingUnit {
            case .price:
                price = embed
            case .piece:
                units = embed
            default:
                weight = embed
            }
        }

        return Cart.Item(sku: product.sku,
                         amount: quantity,
                         scannedCode: self.scannedCode,
                         price: price,
                         weight: weight,
                         units: units,
                         weightUnit: self.encodingUnit)
    }
}

/// a ShoppingCart is a collection of CartItem objects
public final class ShoppingCart {
    
    public static let maxAmount = 9999

    private(set) public var items = [CartItem]()
    private(set) public var session = ""
    private(set) public var lastSaved: Date?

    /// this is intended mainly for the EmbeddedCodesCheckout - use this to append additional codes
    /// (e.g. special "QR code purchase" marker codes) to the list of scanned codes of this cart
    public var additionalCodes: [String]?

    private var timer: Timer?

    private(set) var config: CartConfig

    public init(_ config: CartConfig) {
        self.config = config
        let storage = self.loadCart()
        self.items = storage.items
        self.session = storage.session
    }

    /// check if this cart is outdated (ie. it was last saved more than `config.maxAge` seconds ago)
    public var outdated: Bool {
        return self.isTooOld(self.lastSaved)
    }

    private func isTooOld(_ date: Date?) -> Bool {
        if let date = date, self.config.maxAge > 0 {
            let now = Date.timeIntervalSinceReferenceDate
            return date.timeIntervalSinceReferenceDate < now - self.config.maxAge
        }
        return false
    }

    /// get this cart's `shopId`
    public var shopId: String {
        return self.config.shop.id
    }

    /// get this cart's `loyaltyCard`
    public var loyaltyCard: String? {
        get { return self.config.loyaltyCard }
        set { self.config.loyaltyCard = newValue }
    }

    /// add a Product. if already present and not weight dependent, increase its quantity
    ///
    /// the newly added (or modified) product is moved to the start of the list
    public func add(_ product: Product, quantity: Int = 1, scannedCode: String, embeddedData: Int? = nil, editableUnits: Bool = false, encodingUnit: Units? = nil, referencePrice: Int? = nil) {
        if let index = self.indexOf(product), product.type == .singleItem, product.referenceUnit == nil, encodingUnit == nil {
            self.items[index].quantity += quantity
            let item = self.items.remove(at: index)
            self.items.insert(item, at: 0)
        } else {
            let item = CartItem(quantity, product, scannedCode, embeddedData, editableUnits, encodingUnit, referencePrice)
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
    
    /// change the quantity of the item at `index`
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
        return self.items.reduce(0) { $0 + $1.total(self.config.project) }
    }
    
    /// return the total number of items
    public func numberOfItems() -> Int {
        return self.items.reduce(0) {
            let qty = $1.product.weightDependent ? 1 :  $1.quantity
            return $0 + qty
        }
    }

    /// get all products from this list
    public func allProducts() -> [Product] {
        return (0 ..< self.items.count).compactMap { self.product(at: $0) }
    }
    
    /// remove all items from the cart
    public func removeAll(endSession: Bool = false) {
        self.items.removeAll()
        self.save()

        if endSession {
            CartEvent.sessionEnd(self)
            self.session = ""
        }
    }

    private func indexOf(_ product: Product) -> Int? {
        return self.items.index { $0.product.sku == product.sku }
    }
}

struct CartStorage: Codable {
    let items: [CartItem]
    let session: String
    var lastSaved: Date?

    init() {
        self.items = []
        self.session = ""
    }

    init(_ shoppingCart: ShoppingCart) {
        self.items = shoppingCart.items
        self.session = shoppingCart.session
        self.lastSaved = shoppingCart.lastSaved
    }
}

// MARK: - Persistence
extension ShoppingCart {

    private func cartUrl() -> URL {
        let url = URL(fileURLWithPath: self.config.directory)
        return url.appendingPathComponent(self.config.project.id + ".json")
    }

    /// persist this shopping cart to disk
    private func save() {
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: self.config.directory) {
                try fileManager.createDirectory(atPath: self.config.directory, withIntermediateDirectories: true, attributes: nil)
            }

            self.lastSaved = Date()
            if self.session == "" {
                self.session = UUID().uuidString
                CartEvent.sessionStart(self)
            }
            let storage = CartStorage(self)
            let encodedItems = try JSONEncoder().encode(storage)
            try encodedItems.write(to: self.cartUrl(), options: .atomic)
        } catch let error {
            Log.error("error saving cart \(self.config.project.id): \(error)")
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            CartEvent.cart(self)
        }
    }

    // load this shoppping cart from disk
    private func loadCart() -> CartStorage {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: self.cartUrl().path) {
            return CartStorage()
        }
        
        do {
            let data = try Data(contentsOf: self.cartUrl())
            let storage = try JSONDecoder().decode(CartStorage.self, from: data)
            if self.isTooOld(storage.lastSaved) {
                return CartStorage()
            }
            return storage
        } catch let error {
            Log.error("error loading cart \(self.config.project.id): \(error)")
            return CartStorage()
        }
    }

    /// update the products in this shopping cart, e.g. after a database update was downloaded
    public func updateProducts() {
        let provider = SnabbleAPI.productProvider(for: self.config.project)
        var newItems = [CartItem]()
        for item in self.items {
            if let newItem = CartItem(updating: item, provider, self.config.shop.id) {
                newItems.append(newItem)
            } else {
                newItems.append(item)
            }
        }
        self.items = newItems
        self.save()
    }

}

extension ShoppingCart {

    func createCart() -> Cart {
        let items = self.items.map { $0.cartItem() }
        let customerInfo = Cart.CustomerInfo(loyaltyCard: self.loyaltyCard)
        return Cart(session: self.session, shopID: self.shopId, customer: customerInfo, items: items)
    }

}

// MARK: send events
struct CartEvent {
    static func sessionStart(_ cart: ShoppingCart) {
        let event = AppEvent(.sessionStart, session: cart.session, project: cart.config.project, shopId: cart.shopId)
        event.post()
    }

    static func sessionEnd(_ cart: ShoppingCart) {
        let event = AppEvent(.sessionEnd, session: cart.session, project: cart.config.project, shopId: cart.shopId)
        event.post()
    }

    static func cart(_ cart: ShoppingCart) {
        let event = AppEvent(cart)
        event.post()
    }

}
