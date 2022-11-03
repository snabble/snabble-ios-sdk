//
//  ProductRequest.swift
//  
//
//  Created by Uwe Tilemann on 23.10.22.
//

import Combine
import GRDB
import GRDBQuery

struct ProductFetchConfiguration {
    let sql: (query: String, arguments: StatementArguments)
    let shopId: SnabbleCore.Identifier<Shop>
    let fetchPricesAndBundles: Bool
    let productAvailability: ProductAvailability

    let productHandler: ((Result<Product, ProductLookupError>) -> Void)
    let scannedProductHandler: ((Result<ScannedProduct, ProductLookupError>) -> Void)

    var query: String {
        return sql.query
    }
    var arguments: StatementArguments {
        return sql.arguments
    }
    init(sql: (query: String, arguments: StatementArguments) = ("", []),
         shopId: SnabbleCore.Identifier<Shop>,
         fetchPricesAndBundles: Bool = true,
         productAvailability: ProductAvailability = .inStock,
         productHandler: @escaping ((Result<Product, ProductLookupError>) -> Void) = {_ in},
         scannedProductHandler: @escaping ((Result<ScannedProduct, ProductLookupError>) -> Void) = {_ in}) {
        self.sql = sql
        self.shopId = shopId
        self.fetchPricesAndBundles = fetchPricesAndBundles
        self.productAvailability = productAvailability
        self.productHandler = productHandler
        self.scannedProductHandler = scannedProductHandler

    }
}

struct ProductRequest: Queryable {
    static func == (lhs: ProductRequest, rhs: ProductRequest) -> Bool {
        return lhs.fetchConfiguration.query == rhs.fetchConfiguration.query && lhs.fetchConfiguration.arguments == rhs.fetchConfiguration.arguments
    }
    var fetchConfiguration: ProductFetchConfiguration
    
    static var defaultValue: [Product] { [] }

    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Product], Error> {
        // Build the publisher from the general-purpose read-only access
        // granted by `appDatabase.databaseReader`.
        ValueObservation
            .tracking { db in
                let rows = try Row.fetchAll(db, sql: fetchConfiguration.query, arguments: fetchConfiguration.arguments)
                
                return try rows.compactMap { row in
                    return try product(db, from: row, configuration: fetchConfiguration)
                }
            }
            .publisher(
                in: appDatabase.databaseReader,
                // The `.immediate` scheduling feeds the view right on
                // subscription, and avoids an undesired animation when the
                // application starts.
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    func publisher(in appDatabase: AppDatabase, codes: [(String, String)]) -> AnyPublisher<ScannedProduct?, Error> {
        // Build the publisher from the general-purpose read-only access
        // granted by `appDatabase.databaseReader`.
        ValueObservation
            .tracking { db in
                
                for (code, template) in codes {
                    if let scannedProduct = product(db, code: code, template: template, configuration: fetchConfiguration) {
                        return scannedProduct
                    }
                }
                return nil
            }
            .publisher(
                in: appDatabase.databaseReader,
                // The `.immediate` scheduling feeds the view right on
                // subscription, and avoids an undesired animation when the
                // application starts.
                scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    private func product(_ db: Database, code: String, template: String, configuration: ProductFetchConfiguration) -> ScannedProduct? {

        do {
            let sql = SQLQuery.productSql(code: code, template: template, shopId: configuration.shopId, availability: configuration.productAvailability)
                        
            if let row = try? Row.fetchOne(db, sql: sql.query, arguments: sql.arguments),
               let product = try product(db, from: row, configuration: configuration) {
                let codeEntry = product.codes.first { $0.code == code }
                let transmissionCode = codeEntry?.transmissionCode
                let specifiedQuantity = codeEntry?.specifiedQuantity
                let transmissionTemplate = codeEntry?.transmissionTemplate
                return ScannedProduct(product, code, transmissionCode,
                                      templateId: template,
                                      transmissionTemplateId: transmissionTemplate,
                                      specifiedQuantity: specifiedQuantity)
            } else {
                if let code = code.extractLeadingZerosFromCode() {
                    return product(db, code: code, template: template, configuration: configuration)
                }
            }
        } catch {
            print("productByScannableCode db error: \(error)")
        }
        return nil
    }
    
    private func product(_ db: Database, from row: Row, configuration: ProductFetchConfiguration) throws -> Product? {
        
        guard let sku = row["sku"] as? String else {
            return nil
        }
        let priceRow = try fetchPrice(db, row: row, configuration: configuration)
        let bundles = try fetchBundles(db, row: row, configuration: configuration)
        let deposit = try fetchDeposit(db, row: row, configuration: configuration)

        let mappingValues = Product.MappingValues(sku: sku, row: row, bundles: bundles, deposit: deposit)
        
        return Product.map(productRow: row, priceRow: priceRow, values: mappingValues)
    }
    
    private func fetchBundles(_ db: Database, row: Row, configuration: ProductFetchConfiguration) throws -> [Product] {
        if configuration.fetchPricesAndBundles, let sku = row["bundleSku"] as? String {
            let sql = SQLQuery.productSql(bundledSku: sku, shopId: configuration.shopId, availability: configuration.productAvailability)
            
            let rows = try Row.fetchAll(db, sql: sql.query, arguments: sql.arguments)
            return try rows.compactMap { row in
                return try product(db, from: row, configuration: fetchConfiguration)
            }
        }
        return []
    }

    private func fetchPrice(_ db: Database, row: Row, configuration: ProductFetchConfiguration) throws -> Row {
        if configuration.fetchPricesAndBundles, let sku = row["sku"] as? String {
            let firstSQL = SQLQuery.priceSql(sku: sku, shopId: configuration.shopId)
            let firstRows = try Row.fetchAll(db, sql: firstSQL.query, arguments: firstSQL.arguments)
            if let priceRow = firstRows.first {
                return priceRow
            } else {
                let secondSQL = SQLQuery.priceSql(sku: sku)
                let secondRows = try Row.fetchAll(db, sql: secondSQL.query, arguments: secondSQL.arguments)
                if let priceRow = secondRows.first {
                    return priceRow
                }
            }
        }
        return row
    }
    
    private func fetchDeposit(_ db: Database, row: Row, configuration: ProductFetchConfiguration) throws -> Product.Deposit {
        // find deposit SKU
        var depositPrice: Int?
        let sku = row["depositSku"] as? String
        
        if configuration.fetchPricesAndBundles, let depositSku = sku {
            let sql = SQLQuery.productSql(sku: depositSku, shopId: configuration.shopId, availability: configuration.productAvailability)
            
            let firstRows = try Row.fetchAll(db, sql: sql.query, arguments: sql.arguments)
            if let depositRow = firstRows.first {
                let depositConfiguration = ProductFetchConfiguration(sql: sql,
                                                                     shopId: configuration.shopId,
                                                                     fetchPricesAndBundles: true,
                                                                     productAvailability: configuration.productAvailability)
             
                if let depositProduct = try product(db, from: depositRow, configuration: depositConfiguration) {
                    depositPrice = depositProduct.price(nil)
                }
            }
        }
        return Product.Deposit(sku: sku, price: depositPrice)
    }
}
