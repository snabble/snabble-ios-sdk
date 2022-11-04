//
//  ProductModel.swift
//  
//
//  Created by Uwe Tilemann on 21.10.22.
//

import Foundation
import Combine
import GRDB
import GRDBQuery

public struct AppDatabase {
    /// Creates an `AppDatabase`, and make sure the database schema is ready.
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
    }
    
    /// Provides access to the database.
    ///
    /// Application can use a `DatabasePool`, while SwiftUI previews and tests
    /// can use a fast in-memory `DatabaseQueue`.
    ///
    /// See <https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections>
    private let dbWriter: any DatabaseWriter
}

// MARK: - Database Access: Reads

extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
}

/// Make a product `Swift.Identifiable`
extension Product: Swift.Identifiable {
    public var id: String {
        return sku
    }
}

// MARK: - Publisher object that emits published products

public final class ProductModel: ObservableObject {
    var database: AppDatabase
   
    public var shop: Shop
    public var shopId: SnabbleCore.Identifier<Shop> {
        return shop.id
    }
    
    /// Emits changes on requested array of `Product`
    @Published public var products: [Product]
    
    /// Emits changes on a requested `ScannedProduct`
    public var scannedProduct: ScannedProduct? {
        didSet {
            scannedProductPublisher.send(scannedProduct)
        }
    }
    
    var cancellable = Set<AnyCancellable>()

    /// default availabilty (if no record in `availabilities` is found
    public var defaultAvailability: ProductAvailability
    
    /// Emits if a ScannedProduct changed
    /// - `Output` is an optional `ScannedProduct`
    public var scannedProductPublisher = CurrentValueSubject<ScannedProduct?, Never>(nil)

    public init?(productStore: ProductStore, shop: Shop) {
        guard let database = productStore.database as? DatabaseQueue else {
            return nil
        }
        do {
            self.database = try AppDatabase(database)
            self.shop = shop
            self.defaultAvailability = productStore.productAvailability
            self.products = []
            self.scannedProduct = nil
        } catch {
            fatalError("can't access database")
        }
    }
    
    /// Emits a Product action
    /// - `Output` is a `Product`
    public let productActionPublisher = PassthroughSubject<Product, Never>()
}

// MARK: - Database Publisher

extension ProductModel {
    
    func requestProducts(with configuration: ProductFetchConfiguration) {
        ProductRequest(fetchConfiguration: configuration)
            .publisher(in: self.database)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                    configuration.productHandler(Result.failure(ProductLookupError.from(error) ?? .notFound))
                case .finished:
                    break
                }
            } receiveValue: { [weak self] products in
                self?.products = products
                
                if let product = products.first {
                    configuration.productHandler(Result.success(product))
                } else {
                    configuration.productHandler(Result.failure(.notFound))
                }
            }
            .store(in: &cancellable)
    }
    
    func requestScannedProduct(with configuration: ProductFetchConfiguration, codes: [(String, String)]) {
        ProductRequest(fetchConfiguration: configuration)
            .publisher(in: self.database, codes: codes)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                    configuration.scannedProductHandler(Result.failure(ProductLookupError.from(error) ?? .notFound))
                case .finished:
                    break
                }
            } receiveValue: { [weak self] product in
                
                self?.scannedProduct = product
                
                if let scannedProduct = self?.scannedProduct {
                    configuration.scannedProductHandler(Result.success(scannedProduct))
                } else {
                    configuration.scannedProductHandler(Result.failure(.notFound))
                }
            }
            .store(in: &cancellable)
    }
}

// MARK: - ProductProviding implementation

extension ProductModel: ProductProviding {
    
    public var productAvailability: ProductAvailability {
        return defaultAvailability
    }

    public func productBy(sku: String, shopId: SnabbleCore.Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<Product, ProductLookupError>) -> Void) {
        
        let sql = SQLQuery.productSql(sku: sku, shopId: shopId, availability: self.productAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability, productHandler: completion)
        
        requestProducts(with: fetchConfiguration)
    }

    public func productsBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: SnabbleCore.Identifier<Shop>) -> [Product] {
        guard !prefix.isEmpty else {
            self.products = []
            return []
        }
        
        let sql = SQLQuery.productSql(prefix: prefix, filterDeposits: filterDeposits, templates: templates, shopId: shopId, availability: self.productAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: false, productAvailability: self.productAvailability)
        requestProducts(with: fetchConfiguration)

        return []
    }

    public func productsBy(name: String, filterDeposits: Bool) -> [Product] {
        let sql = SQLQuery.productSql(name: name, filterDeposits: filterDeposits, shopId: shopId, availability: self.productAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability)
        requestProducts(with: fetchConfiguration)

        return []
    }

    public func productsBy(skus: [String], shopId: SnabbleCore.Identifier<Shop>) -> [Product] {
        
        let sql = SQLQuery.productSql(skus: skus, shopId: shopId, availability: self.productAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability)
        requestProducts(with: fetchConfiguration)

        return []
    }

    public func productBy(sku: String, shopId: SnabbleCore.Identifier<Shop>) -> Product? {
        
        let sql = SQLQuery.productSql(sku: sku, shopId: shopId, availability: self.productAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability)
        requestProducts(with: fetchConfiguration)

        return nil
    }

    public func scannedProductBy(codes: [(String, String)], shopId: SnabbleCore.Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<ScannedProduct, ProductLookupError>) -> Void) {
        let fetchConfiguration = ProductFetchConfiguration(shopId: shopId, fetchPricesAndBundles: false, productAvailability: self.productAvailability, scannedProductHandler: completion)

        requestScannedProduct(with: fetchConfiguration, codes: codes)
    }

    public func scannedProductBy(codes: [(String, String)], shopId: SnabbleCore.Identifier<Shop>) -> ScannedProduct? {
        let fetchConfiguration = ProductFetchConfiguration(shopId: shopId, fetchPricesAndBundles: false, productAvailability: self.productAvailability)

        requestScannedProduct(with: fetchConfiguration, codes: codes)

        return nil
    }
}

// MARK: - ProductProviding convenience functions

extension ProductModel {
    public func productsBy(prefix: String) -> [Product] {
        productsBy(prefix: prefix, shopId: self.shopId)
    }
    
    public func productBy(sku: String) -> Product? {
        self.productBy(sku: sku, shopId: self.shopId)
    }
    
    public func productBy(sku: String, completion: @escaping (Result<Product, ProductLookupError>) -> Void) {
        self.productBy(sku: sku, shopId: self.shopId, forceDownload: true, completion: completion)
    }
    
    public func scannedProduct(for product: Product) -> ScannedProduct? {
        guard let codeEntry = product.codes.first else {
            return nil
        }
                
        let fetchConfiguration = ProductFetchConfiguration(shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability)
        
        requestScannedProduct(with: fetchConfiguration, codes: [(codeEntry.code, codeEntry.template)])

        return nil
    }
}
