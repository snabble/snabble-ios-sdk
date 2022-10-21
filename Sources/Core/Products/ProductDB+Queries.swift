//
//  ProductDB+Queries.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import GRDB

extension ProductAvailability: DatabaseValueConvertible { }

// MARK: - low-level db queries
enum SQLQuery {
    static let groupDelimiter = "•" // use a non-ASCII character as the delimiter for group_concat
    
    static let productQuery = """
        select
            p.*, 0 as listPrice, null as discountedPrice, null as customerCardPrice, null as basePrice,
            null as code_encodingUnit,
            (select group_concat(sc.code, '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as codes,
            (select group_concat(sc.template, '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as templates,
            (select group_concat(ifnull(sc.encodingUnit, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as encodingUnits,
            (select group_concat(ifnull(sc.transmissionCode, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as transmissionCodes,
            (select group_concat(ifnull(sc.transmissionTemplate, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as transmissionTemplates,
            (select group_concat(ifnull(sc.isPrimary, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as isPrimary,
            (select group_concat(ifnull(sc.specifiedQuantity, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as specifiedQuantity,
            ifnull((select a.value from availabilities a where a.sku = p.sku and a.shopID = ?), ?) as availability
        from products p
        """
    
    static let productQueryUnits = """
        select
            p.*, 0 as listPrice, null as discountedPrice, null as customerCardPrice, null as basePrice,
            s.encodingUnit as code_encodingUnit,
            (select group_concat(sc.code, '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as codes,
            (select group_concat(sc.template, '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as templates,
            (select group_concat(ifnull(sc.encodingUnit, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as encodingUnits,
            (select group_concat(ifnull(sc.transmissionCode, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as transmissionCodes,
            (select group_concat(ifnull(sc.transmissionTemplate, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as transmissionTemplates,
            (select group_concat(ifnull(sc.isPrimary, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as isPrimary,
            (select group_concat(ifnull(sc.specifiedQuantity, ''), '\(groupDelimiter)') from scannableCodes sc where sc.sku = p.sku) as specifiedQuantity,
            ifnull((select a.value from availabilities a where a.sku = p.sku and a.shopID = ?), ?) as availability
        from products p
        join scannableCodes s on s.sku = p.sku
        where s.code = ? and s.template = ?
        """
    
    static func productSql(sku: String, shopId: Identifier<Shop>, availability: ProductAvailability) -> (query: String, arguments: StatementArguments) {
        return (productQuery + " where p.sku = ?", [shopId.rawValue, availability, sku])
    }
    
    static func productSql(skus: [String], shopId: Identifier<Shop>, availability: ProductAvailability) -> (query: String, arguments: StatementArguments) {
        let list = skus.map { "\'\($0)\'" }.joined(separator: ",")
        
        return (productQuery + " where p.sku in (\(list))", [shopId.rawValue, availability])
    }
    
    static func productSql(code: String, template: String, shopId: Identifier<Shop>, availability: ProductAvailability) -> (query: String, arguments: StatementArguments) {
        return (productQueryUnits, [shopId.rawValue, availability, code, template])
    }
    
    static func productSql(name: String, filterDeposits: Bool, shopId: Identifier<Shop>, availability: ProductAvailability) -> (query: String, arguments: StatementArguments) {
        let limit = name.count < 5 ? name.count * 100 : -1
        let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
        let query = productQuery + " " + """
                    where p.sku in (select sku from searchByName where name match ? limit ?) \(depositCondition)
                    """
        return (query, [shopId.rawValue, availability, "\(name)*", limit])
    }
    
    static func productSql(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>, availability: ProductAvailability) -> (query: String, arguments: StatementArguments) {
        let limit = 100 //  prefix.count < 5 ? prefix.count * 100 : -1
        let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
        let templateNames = templates ?? [ CodeTemplate.defaultName ]
        let list = templateNames.map { "\'\($0)\'" }.joined(separator: " , ")
        
        let query = productQuery + " " + """
                    join scannableCodes s on s.sku = p.sku
                    where s.template in (\(list))
                        and ((s.code glob ?) or (s.sku glob?))
                        \(depositCondition)
                        and p.weighing != \(ProductType.preWeighed.rawValue)
                        and p.weighing != \(ProductType.depositReturnVoucher.rawValue)
                        and availability != \(ProductAvailability.notAvailable.rawValue)
                    limit ?
                    """
        return (query, [ shopId.rawValue, availability, "\(prefix)*", "\(prefix)*", limit])
    }
    
    static func productSql(bundledSku sku: String, shopId: Identifier<Shop>, availability: ProductAvailability) -> (query: String, arguments: StatementArguments) {
        return (productQuery + " where p.bundledSku = ?", [shopId.rawValue, availability, sku])
    }
    
    static func priceSql(sku: String, shopId: Identifier<Shop>) -> (query: String, arguments: StatementArguments) {
        // find the highest priority category that has a price
        let priceQuery = """
            select * from prices
            join shops on shops.pricingCategory = prices.pricingCategory
            where shops.id = ? and sku = ?
            order by priority desc
            limit 1
        """
        return (priceQuery, [shopId.rawValue, sku])
    }
    
    static func priceSql(sku: String) -> (query: String, arguments: StatementArguments) {
        return ("select * from prices where pricingCategory = 0 and sku = ?", [sku])
    }
}

extension ProductDB {

    func productBy(_ dbQueue: DatabaseQueue, sku: String, shopId: Identifier<Shop>) -> Product? {
        do {
            let sql = SQLQuery.productSql(sku: sku, shopId: shopId, availability: self.defaultAvailability)
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
            let sql = SQLQuery.productSql(skus: skus, shopId: shopId, availability: self.defaultAvailability)
            
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
            let sql = SQLQuery.productSql(code: code, template: template, shopId: shopId, availability: self.defaultAvailability)
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
                if let code = extractLeadingZeros(from: code) {
                    return productBy(dbQueue, code: code, template: template, shopId: shopId)
                }
            }
        } catch {
            self.logError("productByScannableCode db error: \(error)")
        }

        return nil
    }

    /// check if `code` is a potential 14/13/12/8-digit GTIN code embedded in an or GTIN-14
    /// - Parameter code: the code to test
    /// - Returns: the `code` shortened or `nil`
    private func extractLeadingZeros(from code: String) -> String? {
        switch code.count {
        case 12 where code.hasPrefix("0000"):
            return String(code.suffix(8))
        case 13 where code.hasPrefix("0"):
            return String(code.suffix(12))
        case 14 where code.hasPrefix("0"):
            return String(code.suffix(13))
        default:
            return nil
        }
    }
    
    func productsBy(_ dbQueue: DatabaseQueue, name: String, filterDeposits: Bool, shopId: Identifier<Shop>) -> [Product] {
        do {
            let sql = SQLQuery.productSql(name: name, filterDeposits: filterDeposits, shopId: shopId, availability: self.defaultAvailability)
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
            let sql = SQLQuery.productSql(prefix: prefix, filterDeposits: filterDeposits, templates: templates, shopId: shopId, availability: self.defaultAvailability)
            
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
            return bundles.filter { $0.listPrice != 0 }
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

        let priceRow: Row
        if fetchPriceAndBundles, let pRow = self.getPriceFor(dbQueue, sku: sku, shopId: shopId) {
            priceRow = pRow
        } else {
            priceRow = row
        }

        // find deposit SKU
        let depositSku = row["depositSku"] as? String

        var depositPrice: Int?
        if fetchPriceAndBundles, let dSku = depositSku, let depositProduct = self.productBy(dbQueue, sku: dSku, shopId: shopId) {
            depositPrice = depositProduct.price(nil)
        }

        let bundles = fetchPriceAndBundles ? self.productsBy(dbQueue, bundledSku: sku, shopId: shopId) : []

        let codes = self.buildCodes(row)

        let referenceUnit = Units.from(row["referenceUnit"] as? String)
        var encodingUnit = Units.from(row["encodingUnit"] as? String)
        if let encodingOverride = Units.from(row["code_encodingUnit"] as? String) {
            encodingUnit = encodingOverride
        }

        let product = Product(sku: sku,
                              name: row["name"],
                              description: row["description"],
                              subtitle: row["subtitle"],
                              imageUrl: row["imageUrl"],
                              basePrice: priceRow["basePrice"],
                              listPrice: priceRow["listPrice"],
                              discountedPrice: priceRow["discountedPrice"],
                              customerCardPrice: priceRow["customerCardPrice"],
                              type: ProductType(rawValue: row["weighing"]),
                              codes: codes,
                              depositSku: depositSku,
                              bundledSku: row["bundledSku"],
                              isDeposit: row["isDeposit"] == 1,
                              deposit: depositPrice,
                              saleRestriction: SaleRestriction(row["saleRestriction"]),
                              saleStop: row["saleStop"] ?? false,
                              bundles: bundles,
                              referenceUnit: referenceUnit,
                              encodingUnit: encodingUnit,
                              scanMessage: row["scanMessage"],
                              availability: ProductAvailability(rawValue: row["availability"]),
                              notForSale: row["notForSale"] ?? false)

        return product
    }

    private func getPriceFor(_ dbQueue: DatabaseQueue, sku: String, shopId: Identifier<Shop>) -> Row? {
        do {
            let row = try dbQueue.inDatabase { db in
                let priceSql = SQLQuery.priceSql(sku: sku, shopId: shopId)
                
                return try self.fetchOne(db, sql: priceSql.query, arguments: priceSql.arguments)
            }
            if row != nil {
                // we have a price in the given category, return it
                return row
            }

            // no price in the category, try the default category, 0
            let row2 = try dbQueue.inDatabase { db in
                let priceSql = SQLQuery.priceSql(sku: sku)
                return try self.fetchOne(db, sql: priceSql.query, arguments: priceSql.arguments)
            }
            return row2
        } catch {
            self.logError("getPriceRowForSku db error: \(error)")
        }
        return nil
    }

    private func buildCodes(_ row: Row) -> [ScannableCode] {
        guard
            let rawCodes = row["codes"] as? String,
            let rawTransmits = row["transmissionCodes"] as? String,
            let rawTemplates = row["templates"] as? String,
            let rawTxTemplates = row["transmissionTemplates"] as? String,
            let rawUnits = row["encodingUnits"] as? String,
            let rawPrimary = row["isPrimary"] as? String,
            let rawSpecifiedQuantity = row["specifiedQuantity"] as? String
        else {
            return []
        }

        let codes = rawCodes.components(separatedBy: SQLQuery.groupDelimiter)
        let templates = rawTemplates.components(separatedBy: SQLQuery.groupDelimiter)
        let transmits = rawTransmits.components(separatedBy: SQLQuery.groupDelimiter)
        let txTemplates = rawTxTemplates.components(separatedBy: SQLQuery.groupDelimiter)
        let units = rawUnits.components(separatedBy: SQLQuery.groupDelimiter)
        let primary = rawPrimary.components(separatedBy: SQLQuery.groupDelimiter)
        let specifiedQuantity = rawSpecifiedQuantity.components(separatedBy: SQLQuery.groupDelimiter).map { Int($0) }

        assert(codes.count == templates.count)
        assert(codes.count == transmits.count)
        assert(codes.count == units.count)
        assert(codes.count == primary.count)
        assert(codes.count == specifiedQuantity.count)
        assert(codes.count == txTemplates.count)

        var primaryTransmission: String?
        if let primaryIndex = primary.firstIndex(where: { $0 == "1" }) {
            let transmit = transmits[primaryIndex].isEmpty ? nil : transmits[primaryIndex]
            let code = codes[primaryIndex].isEmpty ? nil : codes[primaryIndex]
            primaryTransmission = transmit ?? code
        }

        var scannableCodes = [ScannableCode]()
        for idx in 0 ..< codes.count {
            let transmit = transmits[idx].isEmpty ? nil : transmits[idx]
            let code = ScannableCode(code: codes[idx],
                                     template: templates[idx],
                                     transmissionCode: primaryTransmission ?? transmit,
                                     encodingUnit: Units.from(units[idx]),
                                     specifiedQuantity: specifiedQuantity[idx],
                                     transmissionTemplate: txTemplates[idx])
            scannableCodes.append(code)
        }
        return scannableCodes
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
