//
//  File.swift
//  
//
//  Created by Uwe Tilemann on 21.10.22.
//

import Foundation
import Combine
import GRDB
import GRDBQuery
import SwiftUI

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

// This demo app does not provide any specific reading method, and instead
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
}

extension Product: Swift.Identifiable {
    public var id: String {
        return sku
    }
}

public final class ProductViewModel: ObservableObject {
    var database: AppDatabase
    var shopId: SnabbleCore.Identifier<Shop>
    
    //    @Binding var product: Product
    @Published public var products: [Product]
    @Published public var scannedProduct: ScannedProduct?
    
    var cancellable = Set<AnyCancellable>()

    /// default availabilty (if no record in `availabilities` is found
    public var defaultAvailability: ProductAvailability
    
    public init?(database db: AnyObject, shopID: SnabbleCore.Identifier<Shop>, availability: ProductAvailability = .inStock) {
        guard let database = db as? DatabaseQueue else {
            return nil
        }
        do {
            self.database = try AppDatabase(database)
            self.shopId = shopID
            self.defaultAvailability = availability
            self.products = []
            self.scannedProduct = nil
        } catch {
            fatalError("can't access database")
        }
    }
    
    /// Emits if the widget triigers the action
    /// - `Output` is a `DynamicAction`
    public let actionPublisher = PassthroughSubject<Product, Never>()
}

extension ProductViewModel: ProductProviding {
    
    func requestProducts(with configuration: ProductFetchConfiguration) {
        ProductRequest(fetchConfiguration: configuration)
            .publisher(in: self.database)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("finished")
                }
            } receiveValue: { [weak self] products in
                
                self?.products = products
                print("got \(products)")
            }
            .store(in: &cancellable)
    }
    
    public var productAvailability: ProductAvailability {
        return defaultAvailability
    }
    
    public func productBy(codes: [(String, String)], shopId: SnabbleCore.Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<ScannedProduct, ProductLookupError>) -> Void) {
        completion(Result.failure(.notFound))
    }
    
    public func productBy(sku: String, shopId: SnabbleCore.Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<Product, ProductLookupError>) -> Void) {
        completion(Result.failure(.notFound))
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
    
    public func productsBy(prefix: String) -> [Product] {
        productsBy(prefix: prefix, shopId: self.shopId)
    }
    
    public func productsBy(name: String, filterDeposits: Bool) -> [Product] {
        let sql = SQLQuery.productSql(name: name, filterDeposits: filterDeposits, shopId: shopId, availability: self.defaultAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability)
        requestProducts(with: fetchConfiguration)

        return []
    }
    
    public func productsBy(skus: [String], shopId: SnabbleCore.Identifier<Shop>) -> [Product] {
        
        let sql = SQLQuery.productSql(skus: skus, shopId: shopId, availability: self.defaultAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability)
        requestProducts(with: fetchConfiguration)

        return []
    }
    
    public func productBy(codes: [(String, String)], shopId: SnabbleCore.Identifier<Shop>) -> ScannedProduct? {
//        let sql = SQLQuery.productSql(code: code, template: template, shopId: shopId, availability: self.defaultAvailability)

        return nil
    }
    
    public func productBy(sku: String, shopId: SnabbleCore.Identifier<Shop>) -> Product? {
        
        let sql = SQLQuery.productSql(sku: sku, shopId: shopId, availability: self.defaultAvailability)
        let fetchConfiguration = ProductFetchConfiguration(sql: sql, shopId: shopId, fetchPricesAndBundles: true, productAvailability: self.productAvailability)
        requestProducts(with: fetchConfiguration)

        return nil
    }
}
