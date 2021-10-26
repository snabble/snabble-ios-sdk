//
//  ShoppingCart.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

/// a ShoppingCart is a collection of CartItem objects
public final class ShoppingCart: Codable {
    public private(set) var items: [CartItem]
    public private(set) var session: String
    public private(set) var lastSaved: Date?
    public private(set) var backendCartInfo: BackendCartInfo?
    public private(set) var paymentMethods: [PaymentMethodDescription]?
    public private(set) var lastCheckoutInfoError: SnabbleError?
    public private(set) var coupons: [CartCoupon]

    // info that the backend requires
    public private(set) var requiredInformation: [RequiredInformation]
    // required info we've already gathered
    public internal(set) var requiredInformationData: [RequiredInformation]

    public let projectId: Identifier<Project>
    public let shopId: Identifier<Shop>

    public private(set) var uuid: String

    internal var checkoutInfoTask: URLSessionDataTask?

    fileprivate var backupItems: [CartItem]?
    fileprivate var backupSession: String?

    public var customerCard: String? {
        didSet {
            self.updateProducts(self.customerCard)
        }
    }

    internal weak var eventTimer: Timer?

    // number of seconds to wait after a local modification is sent to the backend
    private let saveDelay: TimeInterval = 0.5

    private let maxAge: TimeInterval
    private let directory: String?

    public static let maxAmount = 9999

    enum CodingKeys: String, CodingKey {
        case items, session, lastSaved, backendCartInfo, projectId, shopId
        case uuid, backupItems, backupSession, customerCard, maxAge, coupons
        case requiredInformation, requiredInformationData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try container.decode(.items)
        self.session = try container.decode(.session)
        self.lastSaved = try container.decodeIfPresent(.lastSaved)
        self.backendCartInfo = try container.decodeIfPresent(.backendCartInfo)
        self.projectId = try container.decode(.projectId)
        self.shopId = try container.decode(.shopId)
        self.uuid = try container.decodeIfPresent(.uuid) ?? UUID().uuidString
        self.backupItems = try container.decodeIfPresent(.backupItems)
        self.backupSession = try container.decodeIfPresent(.backupSession)
        self.customerCard = try container.decodeIfPresent(.customerCard)
        self.maxAge = try container.decode(.maxAge)
        self.directory = nil
        self.lastCheckoutInfoError = nil
        self.coupons = try container.decodeIfPresent([CartCoupon].self, forKey: .coupons) ?? []
        self.requiredInformation = try container.decodeIfPresent([RequiredInformation].self, forKey: .requiredInformation) ?? []
        self.requiredInformationData = try container.decodeIfPresent([RequiredInformation].self, forKey: .requiredInformationData) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.items, forKey: .items)
        try container.encode(self.session, forKey: .session)
        try container.encodeIfPresent(self.lastSaved, forKey: .lastSaved)
        try container.encodeIfPresent(self.backendCartInfo, forKey: .backendCartInfo)
        try container.encode(self.projectId, forKey: .projectId)
        try container.encode(self.shopId, forKey: .shopId)
        try container.encode(self.uuid, forKey: .uuid)
        try container.encodeIfPresent(self.backupItems, forKey: .backupItems)
        try container.encodeIfPresent(self.backupSession, forKey: .backupSession)
        try container.encodeIfPresent(self.customerCard, forKey: .customerCard)
        try container.encode(self.maxAge, forKey: .maxAge)
        try container.encode(self.coupons, forKey: .coupons)
        try container.encode(self.requiredInformation, forKey: .requiredInformation)
        try container.encode(self.requiredInformationData, forKey: .requiredInformationData)
    }

    public init(_ config: CartConfig) {
        assert(!config.shop.projectId.rawValue.isEmpty, "projectId is required")
        assert(!config.shop.id.rawValue.isEmpty, "shopId is required")
        self.projectId = config.shop.projectId
        self.shopId = config.shop.id
        self.maxAge = config.maxAge
        self.directory = config.directory

        self.session = ""
        self.uuid = ""
        self.items = []
        self.coupons = []
        self.requiredInformation = []
        self.requiredInformationData = []
        self.generateNewUUID()

        if let savedCart = self.load() {
            self.items = savedCart.items
            self.session = savedCart.session
            self.customerCard = savedCart.customerCard
            self.uuid = savedCart.uuid
            self.coupons = savedCart.coupons
            self.requiredInformation = savedCart.requiredInformation
            self.requiredInformationData = savedCart.requiredInformationData

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
        if self.items.isEmpty {
            self.backupItems = nil
            self.backupSession = nil
        }

        defer { self.save() }
        if item.canMerge, let index = self.items.firstIndex(where: { $0.product.sku == item.product.sku }) {
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

    func replaceItem(at index: Int, with replacement: CartItem) {
        self.items.remove(at: index)
        self.items.insert(replacement, at: index)
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

    func backendItems() -> [Cart.Item] {
        var items = self.items.flatMap { $0.cartItems }
        let coupons = self.coupons.map { $0.cartItem }
        items.append(contentsOf: coupons)

        return items
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
    /// - Parameters:
    ///   - endSession: true to end this cart session (ie. after a successful checkout)
    ///   - keepBackup: true to keep a backup of the cart items (ie. after an offline checkout)
    public func removeAll(endSession: Bool, keepBackup: Bool) {
        if keepBackup {
            self.backupItems = self.items
            self.backupSession = self.session
        } else {
            self.backupItems = nil
            self.backupSession = nil
        }

        self.items.removeAll()
        self.coupons.removeAll()
        self.requiredInformation = []
        self.requiredInformationData = []

        if endSession {
            CartEvent.sessionEnd(self)
            self.session = ""
        }
        self.save()
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
    }

    public func restoreCart() {
        guard
            let backupItems = self.backupItems,
            !backupItems.isEmpty,
            self.items.isEmpty
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
        guard let backupItems = self.backupItems else {
            return false
        }
        return !backupItems.isEmpty
    }

    /// update the products in this shopping cart, e.g. after a database update was downloaded
    /// or when the customer card was changed
    public func updateProducts(_ customerCard: String? = nil) {
        guard let project = SnabbleAPI.project(for: self.projectId) else {
            return
        }

        let provider = SnabbleAPI.productProvider(for: project)
        var newItems = [CartItem]()
        for item in self.items {
            // TODO: don't rely on on products being available locally?
            if let newItem = CartItem(updating: item, provider, self.shopId, customerCard) {
                newItems.append(newItem)
            } else {
                newItems.append(item)
            }
        }
        self.items = newItems
        self.save(postEvent: false)
        CartEvent.cart(self)
    }

    func generateNewUUID() {
        self.uuid = UUID().uuidString
    }
}

// MARK: - Coupons
extension ShoppingCart {
    public func addCoupon(_ coupon: Coupon, scannedCode: String? = nil) {
        let index = coupons.firstIndex(where: { $0.coupon.id == coupon.id })
        if index == nil {
            coupons.append(CartCoupon(coupon: coupon, scannedCode: scannedCode))
            self.save()
        }
    }

    public func removeCoupon(_ coupon: Coupon) {
        coupons.removeAll { $0.coupon.id == coupon.id }
        self.save()
    }
}

// MARK: - Persistence
extension ShoppingCart {
    private func cartUrl(_ directory: String) -> URL {
        let url = URL(fileURLWithPath: directory)
        return url.appendingPathComponent(self.projectId.rawValue + ".json")
    }

    /// persist this shopping cart to disk
    private func save(postEvent: Bool = true) {
        if postEvent {
            self.backendCartInfo = nil
            self.generateNewUUID()
        }

        if let directory = self.directory {
            do {
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: directory) {
                    try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
                }

                self.lastSaved = Date()
                if self.session.isEmpty {
                    self.session = UUID().uuidString
                    CartEvent.sessionStart(self)
                }

                let data = try JSONEncoder().encode(self)
                try data.write(to: self.cartUrl(directory), options: .atomic)
            } catch let error {
                Log.error("error saving cart \(self.projectId): \(error)")
            }
        }

        if postEvent {
            DispatchQueue.main.async {
                self.eventTimer?.invalidate()
                self.eventTimer = Timer.scheduledTimer(withTimeInterval: self.saveDelay, repeats: false) { _ in
                    CartEvent.cart(self)
                }
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
    static let snabbleCartUpdating = Notification.Name("snabbleCartUpdating")
    static let snabbleCartUpdated = Notification.Name("snabbleCartUpdated")
}

// MARK: backend connection
extension ShoppingCart {
    func createCart() -> Cart {
        return Cart(self, clientId: SnabbleAPI.clientId, appUserId: SnabbleAPI.appUserId?.userId)
    }

    func createCheckoutInfo(userInitiated: Bool = false, completion: @escaping (Bool) -> Void) {
        guard
            let project = SnabbleAPI.project(for: self.projectId),
            !self.items.isEmpty
        else {
            completion(false)
            return
        }

        if !userInitiated {
            NotificationCenter.default.post(name: .snabbleCartUpdating, object: self)
        }

        self.createCheckoutInfo(project, timeout: 3) { result in
            switch result {
            case .failure(let error):
                Log.warn("createCheckoutInfo failed: \(error)")
                if error.isUrlError(.cancelled) {
                    self.backendCartInfo = nil
                    self.paymentMethods = nil
                    self.lastCheckoutInfoError = error
                }
                completion(false)
            case .success(let info):
                let session = info.checkoutInfo.session
                Log.info("createCheckoutInfo succeeded: \(session)")
                self.backendCartInfo = BackendCartInfo(info.checkoutInfo)
                self.paymentMethods = info.checkoutInfo.paymentMethods
                self.requiredInformation = info.checkoutInfo.requiredInformation

                let ids = self.requiredInformation.map { $0.id }
                self.requiredInformationData.removeAll { !ids.contains($0.id) }

                self.lastCheckoutInfoError = nil
                self.save(postEvent: false)
                completion(true)
            }
            if !userInitiated {
                NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
            }
        }
    }
}
