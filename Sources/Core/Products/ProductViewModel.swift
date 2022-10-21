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

struct AppDatabase {
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

public class ProductViewModel: ObservableObject {
    var database: AppDatabase
    /// default availabilty (if no record in `availabilities` is found
    public var defaultAvailability = ProductAvailability.inStock
   
    @Binding var product: Product
    @Binding var products: [Product]
    
    var cancellable = Set<AnyCancellable>()

    public init?(db: DatabaseQueue) {
        do {            
            // Create the AppDatabase
            self.database = try AppDatabase(db)
        } catch {
            print(error)
            return nil
        }
    }

    public init?(path: String) {
        do {
            let dbPool = try DatabasePool(path: path)
            
            // Create the AppDatabase
            self.database = try AppDatabase(dbPool)
        } catch {
            print(error)
            return nil
        }
    }
}

extension ProductViewModel: ProductProviding {
    public func productBy(codes: [(String, String)], shopId:SnabbleCore.Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<ScannedProduct, ProductLookupError>) -> Void) {
    }
    
    public func productBy(sku: String, shopId: SnabbleCore.Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<Product, ProductLookupError>) -> Void) {
    }
    
    public func productsBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: SnabbleCore.Identifier<Shop>) -> [Product] {
        let sql = SQLQuery.productSql(prefix: prefix, filterDeposits: filterDeposits, templates: templates, shopId: shopId, availability: self.defaultAvailability)
       
        ProductRequestBy(sql: sql)
            .publisher(in: self.database)
            .sink { completion in
                switch (completion) {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("finished")
                }
            } receiveValue: { [weak self] products in
                guard let self = self else { return }
                
                self.products = products
                print("got \(products)")
            }
            .store(in: &cancellable)

        return []
    }
    
    public func productsBy(name: String, filterDeposits: Bool) -> [Product] {
        return []
    }
    
    public func productsBy(skus: [String], shopId: SnabbleCore.Identifier<Shop>) -> [Product] {
        return []

    }
    
    public func productBy(codes: [(String, String)], shopId: SnabbleCore.Identifier<Shop>) -> ScannedProduct? {
        return nil
    }
    
    public func productBy(sku: String, shopId: SnabbleCore.Identifier<Shop>) -> Product? {
        return nil
    }
}

struct ProductRequestBy: Queryable {
    var sql: (query: String, arguments: StatementArguments)
    
    static var defaultValue: [Products] { [] }

    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Products], Error> {
        // Build the publisher from the general-purpose read-only access
        // granted by `appDatabase.databaseReader`.
        // Some apps will prefer to call a dedicated method of `appDatabase`.
        ValueObservation
            .tracking { db in
                let rows = try Row.fetchAll(db, sql: sql.query, arguments: sql.arguments)
                
                return rows.compactMap { self.productFrom(db, row: $0, shopId: shopId, fetchPriceAndBundles: false) }
            }
            .publisher(
                in: appDatabase.databaseReader,
                // The `.immediate` scheduling feeds the view right on
                // subscription, and avoids an undesired animation when the
                // application starts.
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

struct PriceRequestBy: Queryable {
    var sku: String
    var shopId: SnabbleCore.Identifier<Shop>
    
    static var defaultValue: [Row] { [] }

    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Row], Error> {
        // Build the publisher from the general-purpose read-only access
        // granted by `appDatabase.databaseReader`.
        // Some apps will prefer to call a dedicated method of `appDatabase`.
        ValueObservation
            .tracking { db in
                let firstSQL = SQLQuery.priceSql(sku: sku, shopId: shopId)
                let prices = try Row.fetchAll(db, sql: firstSQL.query, arguments: firstSQL.arguments)
                if !prices.isEmpty {
                    return prices
                }
                
                let secondSQL = SQLQuery.priceSql(sku: sku)
                return try Prices.fetchAll(db, sql: secondSQL.query, arguments: secondSQL.arguments)
            }
            .publisher(
                in: appDatabase.databaseReader,
                // The `.immediate` scheduling feeds the view right on
                // subscription, and avoids an undesired animation when the
                // application starts.
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}
