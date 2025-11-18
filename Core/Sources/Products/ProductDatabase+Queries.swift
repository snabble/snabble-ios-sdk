//
//  ProductDatabase+Queries.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import GRDB

extension ProductAvailability: DatabaseValueConvertible { }

extension String {
    /// check if `code` is a potential 14/13/12/8-digit GTIN code embedded in an or GTIN-14
    /// - Parameter code: the code to test
    /// - Returns: the `code` shortened or `nil`
    func extractLeadingZerosFromCode() -> String? {
        switch self.count {
        case 12 where self.hasPrefix("0000"):
            return String(self.suffix(8))
        case 13 where self.hasPrefix("0"):
            return String(self.suffix(12))
        case 14 where self.hasPrefix("0"):
            return String(self.suffix(13))
        default:
            return nil
        }
    }
}

// MARK: - low-level db queries
extension ProductDatabase {

    func productBy(_ dbQueue: DatabaseQueue, sku: String, shopId: Identifier<Shop>) -> Product? {
        do {
            let sql = SQLQuery.productSql(sku: sku, shopId: shopId, availability: self.productAvailability)
            let row = try dbQueue.inDatabase { db in
                return try self.fetchOne(db, sql: sql.query, arguments: sql.arguments)
            }
            return self.productFrom(dbQueue, row: row, shopId: shopId)
        } catch {
            self.logError("productBySku db error: \(error)")
        }

        return nil
    }

    func productsBy(_ dbQueue: DatabaseQueue, skus: [String], shopId: Identifier<Shop>) -> [Product] {
        do {
            let sql = SQLQuery.productSql(skus: skus, shopId: shopId, availability: self.productAvailability)
            
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, sql: sql.query, arguments: sql.arguments)
            }
            return rows.compactMap { self.productFrom(dbQueue, row: $0, shopId: shopId) }
        } catch {
            self.logError("productsBySku db error: \(error)")
        }
        return []
    }

    func productBy(_ dbQueue: DatabaseQueue, codes: [(String, String)], shopId: Identifier<Shop>) -> ScannedProduct? {
        for (code, template) in codes {
            if let result = self.productBy(dbQueue, code: code, template: template, shopId: shopId) {
                return result
            }
        }

        return nil
    }

    private func productBy(_ dbQueue: DatabaseQueue, code: String, template: String, shopId: Identifier<Shop>) -> ScannedProduct? {
        do {
            let sql = SQLQuery.productSql(code: code, template: template, shopId: shopId, availability: self.productAvailability)
            let row = try dbQueue.inDatabase { db in
                return try fetchOne(db, sql: sql.query, arguments: sql.arguments)
            }
            if let product = productFrom(dbQueue, row: row, shopId: shopId) {
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
                    return productBy(dbQueue, code: code, template: template, shopId: shopId)
                }
            }
        } catch {
            self.logError("productByScannableCode db error: \(error)")
        }

        return nil
    }

    func productsBy(_ dbQueue: DatabaseQueue, name: String, filterDeposits: Bool, shopId: Identifier<Shop>) -> [Product] {
        do {
            let sql = SQLQuery.productSql(name: name, filterDeposits: filterDeposits, shopId: shopId, availability: self.productAvailability)
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, sql: sql.query, arguments: sql.arguments)
            }
            return rows.compactMap { self.productFrom(dbQueue, row: $0, shopId: shopId, fetchPriceAndBundles: false) }
        } catch {
            self.logError("productsByName db error: \(error)")
        }
        return []
    }

    func productsBy(_ dbQueue: DatabaseQueue, prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>) -> [Product] {
        do {
            let sql = SQLQuery.productSql(prefix: prefix, filterDeposits: filterDeposits, templates: templates, shopId: shopId, availability: self.productAvailability)
            
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, sql: sql.query, arguments: sql.arguments)
            }
            return rows.compactMap { self.productFrom(dbQueue, row: $0, shopId: shopId, fetchPriceAndBundles: false) }
        } catch {
            self.logError("productByScannableCodePrefix db error: \(error)")
        }
        return []
    }
    
    func productsBy(_ dbQueue: DatabaseQueue, bundledSku sku: String, shopId: Identifier<Shop>) -> [Product] {
        do {
            let sql = SQLQuery.productSql(bundledSku: sku, shopId: shopId, availability: self.defaultAvailability)
            
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, sql: sql.query, arguments: sql.arguments)
            }
            // get all bundles
            let bundles = rows.compactMap { self.productFrom(dbQueue, row: $0, shopId: shopId) }
            // remove bundles w/o price
            return bundles
        } catch {
            self.logError("productsBundling db error: \(error)")
        }
        return []
    }

    func metadata(_ dbQueue: DatabaseQueue) -> [String: String] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, sql: "select * from metadata")
            }

            let tuples = rows.compactMap { ($0["key"], $0["value"]) as? (String, String) }
            return Dictionary(uniqueKeysWithValues: tuples)
        } catch {
            self.logError("metadata db error: \(error)")
        }
        return [:]
    }

    func createFulltextIndex(_ dbQueue: DatabaseQueue) throws {
        let start = Date.timeIntervalSinceReferenceDate
        try dbQueue.inDatabase { db in
            try db.execute(sql: "drop table if exists searchByName_tmp")
            try db.execute(sql: "create virtual table searchByName_tmp using fts4(sku text, name text, tokenize=unicode61)")
            try db.execute(sql: "insert into searchByName_tmp select sku, name from products")

            try db.execute(sql: "drop table if exists searchByName")
            try db.execute(sql: "alter table searchByName_tmp rename to searchByName")
        }
        let elapsed = Date.timeIntervalSinceReferenceDate - start
        Log.info("FTS index built in \(elapsed)s")
    }

    private func productFrom(_ dbQueue: DatabaseQueue, row: Row?, shopId: Identifier<Shop>, fetchPriceAndBundles: Bool = true) -> Product? {
        guard
            let row = row,
            let sku = row["sku"] as? String
        else {
            return nil
        }

        let priceRow = fetchPrice(dbQueue, row: row, sku: sku, shopId: shopId)
        let deposit = fetchDeposit(dbQueue, depositSku: row["depositSku"] as? String, shopId: shopId)
        let bundles = fetchPriceAndBundles ? self.productsBy(dbQueue, bundledSku: sku, shopId: shopId) : []

        let mappingValues = Product.MappingValues(sku: sku, row: row, bundles: bundles, deposit: deposit)
        
        let product = Product.map(productRow: row, priceRow: priceRow, values: mappingValues)
        
        return product
    }
    
    private func fetchDeposit(_ dbQueue: DatabaseQueue, depositSku: String?, shopId: Identifier<Shop>, fetchPriceAndBundles: Bool = true) -> Product.Deposit {
        // find deposit SKU
        var depositPrice: Int?
        if fetchPriceAndBundles, let dSku = depositSku, let depositProduct = self.productBy(dbQueue, sku: dSku, shopId: shopId) {
            depositPrice = depositProduct.price(nil)
        }
        return Product.Deposit(sku: depositSku, price: depositPrice)
    }
    
    private func fetchPrice(_ dbQueue: DatabaseQueue, row: Row, sku: String, shopId: Identifier<Shop>, fetchPriceAndBundles: Bool = true) -> Row {
        if fetchPriceAndBundles {
            do {
                let row1 = try dbQueue.inDatabase { db in
                    let priceSql = SQLQuery.priceSql(sku: sku, shopId: shopId)
                    
                    return try self.fetchOne(db, sql: priceSql.query, arguments: priceSql.arguments)
                }
                if let priceRow = row1 {
                    // we have a price in the given category, return it
                    return priceRow
                }
                
                // no price in the category, try the default category, 0
                let row2 = try dbQueue.inDatabase { db in
                    let priceSql = SQLQuery.priceSql(sku: sku)
                    return try self.fetchOne(db, sql: priceSql.query, arguments: priceSql.arguments)
                }
                if let priceRow = row2 {
                    return priceRow
                }
            } catch {
                self.logError("getPriceRowForSku db error: \(error)")
            }
        }
        return row
    }
        
    // timing-logging wrappers around Row.fetchOne/fetchAll

    private func fetchOne(_ db: Database, sql query: String, arguments: StatementArguments = StatementArguments()) throws -> Row? {
        let start = Date.timeIntervalSinceReferenceDate
        defer {
            self.logSlowQuery(db, sql: query, arguments: arguments, start)
        }
        return try Row.fetchOne(db, sql: query, arguments: arguments, adapter: nil)
    }

    private func fetchAll(_ db: Database, sql query: String, arguments: StatementArguments = StatementArguments()) throws -> [Row] {
        let start = Date.timeIntervalSinceReferenceDate
        defer {
            self.logSlowQuery(db, sql: query, arguments: arguments, start)
        }
        return try Row.fetchAll(db, sql: query, arguments: arguments, adapter: nil)
    }

    private func logSlowQuery(_ db: Database, sql query: String, arguments: StatementArguments, _ start: TimeInterval) {
        let elapsed = Date.timeIntervalSinceReferenceDate - start

        if Snabble.debugMode && elapsed >= 0.03 {
            Log.info("slow query: \(elapsed)s for \(query) - arguments: \(String(describing: arguments))" )
            // self.queryPlan(db, query, arguments)
        }
    }

    private func queryPlan(_ db: Database, sql query: String, _ arguments: StatementArguments = StatementArguments()) {
        do {
            for explain in try Row.fetchAll(db, sql: "EXPLAIN QUERY PLAN " + query, arguments: arguments) {
                Log.debug("EXPLAIN: \(explain)")
            }
        } catch {
            Log.error("query explain error \(error) for \(query)")
        }
    }
}
