//
//  ShoppingCart.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

/// a ShoppingCart is a collection of CartItem objects
final public class ShoppingCart: Codable {
    private(set) public var items: [CartItem]
    private(set) public var session: String
    private(set) public var lastSaved: Date?
    private(set) public var backendCartInfo: BackendCartInfo?

    public let projectId: String
    public let shopId: String

    internal var checkoutInfoTask: URLSessionDataTask?

    fileprivate var backupItems: [CartItem]?
    fileprivate var backupSession: String?

    public var customerCard: String? {
        didSet {
            self.updateProducts(self.customerCard)
        }
    }

    internal var eventTimer: Timer?

    // number of seconds to wait after a local modification is sent to the backend
    private let saveDelay: TimeInterval = 1.0

    private let maxAge: TimeInterval
    private let directory: String?

    public static let maxAmount = 9999

    enum CodingKeys: String, CodingKey {
        case items, session, lastSaved, backendCartInfo, projectId, shopId, backupItems, backupSession, customerCard, maxAge
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try container.decode(.items)
        self.session = try container.decode(.session)
        self.lastSaved = try container.decodeIfPresent(.lastSaved)
        self.backendCartInfo = try container.decodeIfPresent(.backendCartInfo)
        self.projectId = try container.decode(.projectId)
        self.shopId = try container.decode(.shopId)
        self.backupItems = try container.decodeIfPresent(.backupItems)
        self.backupSession = try container.decodeIfPresent(.backupSession)
        self.customerCard = try container.decodeIfPresent(.customerCard)
        self.maxAge = try container.decode(.maxAge)
        self.directory = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.items, forKey: .items)
        try container.encode(self.session, forKey: .session)
        try container.encodeIfPresent(self.lastSaved, forKey: .lastSaved)
        try container.encodeIfPresent(self.backendCartInfo, forKey: .backendCartInfo)
        try container.encode(self.projectId, forKey: .projectId)
        try container.encode(self.shopId, forKey: .shopId)
        try container.encodeIfPresent(self.backupItems, forKey: .backupItems)
        try container.encodeIfPresent(self.backupSession, forKey: .backupSession)
        try container.encodeIfPresent(self.customerCard, forKey: .customerCard)
        try container.encode(self.maxAge, forKey: .maxAge)
    }

    public init(_ config: CartConfig) {
        assert(config.project.id != "", "empty projects cannot have a shopping cart")
        self.projectId = config.project.id
        self.shopId = config.shop.id
        self.maxAge = config.maxAge
        self.directory = config.directory

        self.session = ""
        self.items = []

        if let savedCart = self.load() {
            self.items = savedCart.items
            self.session = savedCart.session
            self.customerCard = savedCart.customerCard

            self.backupItems = savedCart.backupItems
            self.backupSession = savedCart.backupSession
            self.backendCartInfo = savedCart.backendCartInfo
        }
    }

    /// check if this cart is outdated (ie. it was last saved more than `config.maxAge` seconds ago)
    public var outdated: Bool {
        if let lastSaved = self.lastSaved, self.maxAge > 0 {
            let now = Date.timeIntervalSinceReferenceDate
            return lastSaved.timeIntervalSinceReferenceDate < now - self.maxAge
        }
        return false
    }

    /// add an item. if already present and not weight dependent, increase its quantity
    ///
    /// the newly added (or modified) item is moved to the start of the list
    public func add(_ item: CartItem) {
        if self.items.count == 0 {
            self.backupItems = nil
            self.backupSession = nil
        }
        
        defer { self.save() }
        if let index = self.items.firstIndex(where: { $0.product.sku == item.product.sku }) {
            var existing = self.items[index]
            if existing.canMerge {
                existing.quantity += item.quantity
                self.items.remove(at: index)
                self.items.insert(existing, at: 0)
                return
            }
        }

        self.items.insert(item, at: 0)
    }

    /// delete the entry at position `index`
    public func remove(at index: Int) {
        self.items.remove(at: index)
        self.save()
    }

    public func setQuantity(_ quantity: Int, at index: Int) {
        if self.items[index].editable {
            self.items[index].quantity = quantity
        } else {
            Log.warn("ignored attempt to modify quantity of non-editable item, sku=\(self.items[index].product.sku)")
        }
        self.save()
    }

    public func setQuantity(_ quantity: Int, for item: CartItem) {
        if let index = self.items.firstIndex(where: { $0.product.sku == item.product.sku }) {
            self.setQuantity(quantity, at: index)
        } else {
            Log.warn("setQuantity: item not found, sku=\(item.product.sku)")
        }
    }

    /// current quantity. returns 0 if not present or item cannot be merged with others
    public func quantity(of cartItem: CartItem) -> Int {
        if let existing = self.items.first(where: { $0.product.sku == cartItem.product.sku }) {
            return existing.canMerge ? existing.quantity : 0
        }

        return 0
    }

    /// number of separate items in the cart
    public var numberOfItems: Int {
        return self.items.count
    }

    /// number of products in the cart (sum of all quantities)
    public var numberOfProducts: Int {
        return self.items.reduce(0) { result, item in
            let count = item.product.type == .singleItem ? item.quantity : 1
            return result + count
        }
    }

    func backendItems() -> [BackendCartItem] {
        return self.items.map { $0.cartItem }
    }

    /// return the the total price of all products. nil if unknown, i.e. when there are products with unknown prices in the cart
    public var total: Int? {
        var noPrice = false
        let total = self.items.reduce(0) { acc, item in
            let price = item.price
            if price == 0 {
                noPrice = true
            }
            return acc + price
        }
        return noPrice ? nil : total
    }

    /// remove all items from the cart
    public func removeAll(endSession: Bool = false) {
        self.backupItems = self.items
        self.backupSession = self.session

        self.items.removeAll()
        self.save()
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)

        if endSession {
            CartEvent.sessionEnd(self)
            self.session = ""
        }
    }

    public func restoreCart() {
        guard
            let backupItems = self.backupItems,
            backupItems.count > 0,
            self.items.count == 0
        else {
            return
        }

        self.items = backupItems
        if let backupSession = self.backupSession {
            self.session = backupSession
        }
        self.backupItems = nil
        self.backupSession = nil
    }

    public var backupAvailable: Bool {
        return (self.backupItems?.count ?? 0) > 0
    }

    /// update the products in this shopping cart, e.g. after a database update was downloaded
    /// or when the customer card was changed
    public func updateProducts(_ customerCard: String? = nil) {
        guard let project = SnabbleAPI.projectFor(self.projectId) else {
            return
        }

        let provider = SnabbleAPI.productProvider(for: project)
        var newItems = [CartItem]()
        for item in self.items {
            if let newItem = CartItem(updating: item, provider, self.shopId, customerCard) {
                newItems.append(newItem)
            } else {
                newItems.append(item)
            }
        }
        self.items = newItems
        self.save()
    }
}

// MARK: - Persistence
extension ShoppingCart {

    private func cartUrl(_ directory: String) -> URL {
        let url = URL(fileURLWithPath: directory)
        return url.appendingPathComponent(self.projectId + ".json")
    }

    /// persist this shopping cart to disk
    private func save(postEvent: Bool = true) {
        guard let directory = self.directory else {
            return
        }

        if postEvent {
            self.backendCartInfo = nil
        }

        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directory) {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            }

            self.lastSaved = Date()
            if self.session == "" {
                self.session = UUID().uuidString
                CartEvent.sessionStart(self)
            }

            let data = try JSONEncoder().encode(self)
            try data.write(to: self.cartUrl(directory), options: .atomic)
        } catch let error {
            Log.error("error saving cart \(self.projectId): \(error)")
        }

        if postEvent {
            self.eventTimer?.invalidate()
            self.eventTimer = Timer.scheduledTimer(withTimeInterval: self.saveDelay, repeats: false) { timer in
                CartEvent.cart(self)
            }
        }
    }

    // load this shoppping cart from disk
    private func load() -> ShoppingCart? {
        guard let directory = self.directory else {
            return nil
        }

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: self.cartUrl(directory).path) {
            return nil
        }

        do {
            let data = try Data(contentsOf: self.cartUrl(directory))
            let cart = try JSONDecoder().decode(ShoppingCart.self, from: data)
            if cart.outdated {
                return nil
            }
            return cart
        } catch let error {
            Log.error("error loading cart \(self.projectId): \(error)")
            return nil
        }
    }
}

public extension Notification.Name {
    static let snabbleCartUpdated = Notification.Name("snabbleCartUpdated")
}

// MARK: backend connection
extension ShoppingCart {
    func createCart() -> Cart {
        let customerInfo = Cart.CustomerInfo(loyaltyCard: self.customerCard)
        return Cart(session: self.session, shopID: self.shopId, customer: customerInfo, items: self.backendItems())
    }

    func createCheckoutInfo(userInitiated: Bool = false, completion: @escaping (Bool) -> ()) {
        guard let project = SnabbleAPI.projectFor(self.projectId) else {
            completion(false)
            return
        }

        self.createCheckoutInfo(project, timeout: 2) { result in
            switch result {
            case .failure(let error):
                Log.warn("createCheckoutInfo failed: \(error)")
                self.backendCartInfo = nil
                completion(false)
            case .success(let info):
                let session = info.checkoutInfo.session
                Log.info("createCheckoutInfo succeeded: \(session)")
                let totalPrice = info.checkoutInfo.price.price
                self.backendCartInfo = BackendCartInfo(lineItems: info.checkoutInfo.lineItems, totalPrice: totalPrice)
                self.save(postEvent: false)
                completion(true)
            }
            if !userInitiated {
                NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
            }
        }
    }
}
