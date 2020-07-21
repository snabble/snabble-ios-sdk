//
//  ProductDB+Queries.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import GRDB

extension ProductAvailability: DatabaseValueConvertible { }

// MARK: - low-level db queries
extension ProductDB {

    static let productQuery = """
        select
            p.*, 0 as listPrice, null as discountedPrice, null as customerCardPrice, null as basePrice,
            null as code_encodingUnit,
            (select group_concat(sc.code) from scannableCodes sc where sc.sku = p.sku) as codes,
            (select group_concat(sc.template) from scannableCodes sc where sc.sku = p.sku) as templates,
            (select group_concat(ifnull(sc.encodingUnit, '')) from scannableCodes sc where sc.sku = p.sku) as encodingUnits,
            (select group_concat(ifnull(sc.transmissionCode, '')) from scannableCodes sc where sc.sku = p.sku) as transmissionCodes,
            ifnull((select a.value from availabilities a where a.sku = p.sku and a.shopID = ?), ?) as availability
        from products p
        """

    static let productQueryUnits = """
        select
            p.*, 0 as listPrice, null as discountedPrice, null as customerCardPrice, null as basePrice,
            s.encodingUnit as code_encodingUnit,
            (select group_concat(sc.code) from scannableCodes sc where sc.sku = p.sku) as codes,
            (select group_concat(sc.template) from scannableCodes sc where sc.sku = p.sku) as templates,
            (select group_concat(ifnull(sc.encodingUnit, '')) from scannableCodes sc where sc.sku = p.sku) as encodingUnits,
            (select group_concat(ifnull(sc.transmissionCode, '')) from scannableCodes sc where sc.sku = p.sku) as transmissionCodes,
            ifnull((select a.value from availabilities a where a.sku = p.sku and a.shopID = ?), ?) as availability
        from products p
        join scannableCodes s on s.sku = p.sku
        where s.code = ? and s.template = ?
        """

    func productBySku(_ dbQueue: DatabaseQueue, _ sku: String, _ shopId: String) -> Product? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try self.fetchOne(db,
                    ProductDB.productQuery + " where p.sku = ?",
                    arguments: [shopId, self.defaultAvailability, sku])
            }
            return self.productFromRow(dbQueue, row, shopId)
        } catch {
            self.logError("productBySku db error: \(error)")
        }

        return nil
    }

    func productsBySku(_ dbQueue: DatabaseQueue, _ skus: [String], _ shopId: String) -> [Product] {
        do {
            let list = skus.map { "\'\($0)\'" }.joined(separator: ",")
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db,
                    ProductDB.productQuery + " where p.sku in (\(list))",
                    arguments: [shopId, self.defaultAvailability])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
        } catch {
            self.logError("productsBySku db error: \(error)")
        }
        return []
    }

    func discountedProducts(_ dbQueue: DatabaseQueue, _ shopId: String) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db,
                    ProductDB.productQuery + " " + """
                    left outer join prices pr1 on pr1.sku = p.sku and pr1.pricingCategory = ifnull((select pricingCategory from shops where shops.id = ?), 0)
                    left outer join prices pr2 on pr2.sku = p.sku and pr2.pricingCategory = 0
                    where p.imageUrl is not null and ifnull(pr1.discountedPrice, pr2.discountedPrice) is not null
                    """,
                    arguments: [shopId, self.defaultAvailability, shopId])
                }
            return rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
        } catch {
            self.logError("discountedProducts db error: \(error)")
        }
        return []
    }

    func productByScannableCodes(_ dbQueue: DatabaseQueue, _ codes: [(String, String)], _ shopId: String) -> ScannedProduct? {
        for (code, template) in codes {
            if let result = self.productByScannableCode(dbQueue, code, template, shopId) {
                return result
            }
        }

        return nil
    }

    private func productByScannableCode(_ dbQueue: DatabaseQueue, _ code: String, _ template: String, _ shopId: String) -> ScannedProduct? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try self.fetchOne(db,
                    ProductDB.productQueryUnits,
                    arguments: [shopId, self.defaultAvailability, code, template])
            }
            if let product = self.productFromRow(dbQueue, row, shopId) {
                let codeEntry = product.codes.first { $0.code == code }
                let transmissionCode = codeEntry?.transmissionCode
                return ScannedProduct(product, code, transmissionCode, template)
            }
        } catch {
            self.logError("productByScannableCode db error: \(error)")
        }

        return nil
    }

    func productsByName(_ dbQueue: DatabaseQueue, _ name: String, _ filterDeposits: Bool, _ shopId: String) -> [Product] {
        do {
            let limit = name.count < 5 ? name.count * 100 : -1
            let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db,
                    ProductDB.productQuery + " " + """
                    where p.sku in (select sku from searchByName where foldedName match ? limit ?) \(depositCondition)
                    """,
                    arguments: [shopId, self.defaultAvailability, "\(name)*", limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
        } catch {
            self.logError("productsByName db error: \(error)")
        }
        return []
    }

    func productsByScannableCodePrefix(_ dbQueue: DatabaseQueue, _ prefix: String, _ filterDeposits: Bool, _ templates: [String]?, _ shopId: String) -> [Product] {
        do {
            let limit = 100 //  prefix.count < 5 ? prefix.count * 100 : -1
            let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
            let templateNames = templates ?? [ CodeTemplate.defaultName ]
            let list = templateNames.map { "\'\($0)\'" }.joined(separator: " , ")
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db,
                    ProductDB.productQuery + " " + """
                    join scannableCodes s on s.sku = p.sku
                    where s.template in (\(list))
                        and (s.code glob ?) \(depositCondition)
                        and p.weighing != \(ProductType.preWeighed.rawValue)
                        and availability != \(ProductAvailability.notAvailable.rawValue)
                    limit ?
                    """,
                    arguments: [ shopId, self.defaultAvailability, "\(prefix)*", limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
        } catch {
            self.logError("productByScannableCodePrefix db error: \(error)")
        }
        return []
    }

    func productsBundling(_ dbQueue: DatabaseQueue, _ sku: String, _ shopId: String) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db,
                    ProductDB.productQuery + " where p.bundledSku = ?",
                    arguments: [shopId, self.defaultAvailability, sku])
            }
            // get all bundles
            let bundles = rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
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
                return try self.fetchAll(db, "select * from metadata")
            }

            let tuples = rows.compactMap { ($0["key"], $0["value"]) as? (String, String) }
            return Dictionary(uniqueKeysWithValues: tuples)
        } catch {
            self.logError("metadata db error: \(error)")
        }
        return [:]
    }

    func createFullTextIndex(_ dbQueue: DatabaseQueue) throws {
        let start = Date.timeIntervalSinceReferenceDate
        try dbQueue.inDatabase { db in
            try db.execute(sql: "drop table if exists searchByName_tmp")
            try db.execute(sql: "create virtual table searchByName_tmp using fts4(sku text, foldedname text)")

            let rows = try Row.fetchCursor(db, sql: "select sku, name from products")

            try db.inTransaction {
                while let row = try rows.next() {
                    guard let sku = row["sku"] as? String, let name = row["name"] as? String else {
                        continue
                    }

                    let foldedName = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    try db.execute(sql: "insert into searchByName_tmp values(?, ?)", arguments: [ sku, foldedName ])
                }
                return .commit
            }

            try db.execute(sql: "drop table if exists searchByName")
            try db.execute(sql: "alter table searchByName_tmp rename to searchByName")
            try db.execute(sql: "vacuum")
        }
        let elapsed = Date.timeIntervalSinceReferenceDate - start
        Log.debug("update took \(elapsed)")
    }

    private func productFromRow(_ dbQueue: DatabaseQueue, _ row: Row?, _ shopId: String) -> Product? {
        guard
            let row = row,
            let sku = row["sku"] as? String
        else {
            return nil
        }

        // if we have a shopId, get the price
        let priceRow: Row

        if let pRow = self.getPriceRowForSku(dbQueue, sku, shopId) {
            priceRow = pRow
        } else {
            priceRow = row
        }

        // find deposit SKU
        let depositSku = row["depositSku"] as? String

        var depositPrice: Int?
        if let dSku = depositSku, let depositProduct = self.productBySku(dbQueue, dSku, shopId) {
            depositPrice = depositProduct.price(nil)
        }

        let bundles = self.productsBundling(dbQueue, sku, shopId)

        let codes = self.buildCodes(row["codes"], row["templates"], row["transmissionCodes"], rawUnits: row["encodingUnits"])

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

    private func getPriceRowForSku(_ dbQueue: DatabaseQueue, _ sku: String, _ shopId: String) -> Row? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try self.fetchOne(db,
                    "select * from prices where pricingCategory = ifnull((select pricingCategory from shops where shops.id = ?), 0) and sku = ?",
                    arguments: [shopId, sku])
            }
            if row != nil {
                // we have a price in the given category, return it
                return row
            }

            // no price in the category, try the default category, 0
            let row2 = try dbQueue.inDatabase { db in
                return try self.fetchOne(db, "select * from prices where pricingCategory = 0 and sku = ?", arguments: [sku])
            }
            return row2
        } catch {
            self.logError("getPriceRowForSku db error: \(error)")
        }
        return nil
    }

    private func buildCodes(_ rawCodes: String?, _ rawTemplates: String?, _ rawTransmits: String?, rawUnits: String?) -> [ScannableCode] {
        guard let rawCodes = rawCodes, let rawTransmits = rawTransmits, let rawTemplates = rawTemplates, let rawUnits = rawUnits  else {
            return []
        }

        let codes = rawCodes.components(separatedBy: ",")
        let templates = rawTemplates.components(separatedBy: ",")
        let transmits = rawTransmits.components(separatedBy: ",")
        let units = rawUnits.components(separatedBy: ",")

        assert(codes.count == templates.count)
        assert(codes.count == transmits.count)
        assert(codes.count == units.count)

        var scannableCodes = [ScannableCode]()
        for idx in 0 ..< codes.count {
            let transmissionCode = transmits[idx].isEmpty ? nil : transmits[idx]
            let code = ScannableCode(codes[idx], templates[idx], transmissionCode, Units.from(units[idx]))
            scannableCodes.append(code)
        }
        return scannableCodes
    }

    // timing-logging wrappers around Row.fetchOne/fetchAll

    private func fetchOne(_ db: Database, _ query: String, arguments: StatementArguments = StatementArguments()) throws -> Row? {
        let start = Date.timeIntervalSinceReferenceDate
        defer {
            self.logSlowQuery(db, query, arguments, start)
        }
        return try Row.fetchOne(db, sql: query, arguments: arguments, adapter: nil)
    }

    private func fetchAll(_ db: Database, _ query: String, arguments: StatementArguments = StatementArguments()) throws -> [Row] {
        let start = Date.timeIntervalSinceReferenceDate
        defer {
            self.logSlowQuery(db, query, arguments, start)
        }
        return try Row.fetchAll(db, sql: query, arguments: arguments, adapter: nil)
    }

    private func logSlowQuery(_ db: Database, _ query: String, _ arguments: StatementArguments, _ start: TimeInterval) {
        let elapsed = Date.timeIntervalSinceReferenceDate - start

        if SnabbleAPI.debugMode && elapsed >= 0.01 {
            Log.info("slow query: \(elapsed)s for \(query) - arguments: \(String(describing: arguments))" )
            self.queryPlan(db, query, arguments)
        }
    }

    private func queryPlan(_ db: Database, _ query: String, _ arguments: StatementArguments = StatementArguments()) {
        do {
            for explain in try Row.fetchAll(db, sql: "EXPLAIN QUERY PLAN " + query, arguments: arguments) {
                Log.debug("EXPLAIN: \(explain)")
            }
        } catch {
            Log.error("query explain error \(error) for \(query)")
        }
    }
}
