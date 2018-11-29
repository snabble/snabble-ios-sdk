//
//  ProductDB+Queries.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation
import GRDB


// MARK: - low-level db queries
extension ProductDB {

    static let productQuery = """
        select
            p.*, 0 as listPrice, null as discountedPrice, null as basePrice,
            (select group_concat(sc.code) from scannableCodes sc where sc.sku = p.sku) scannableCodes,
            (select group_concat(w.weighItemId) from weighItemIds w where w.sku = p.sku) weighItemIds,
            (select group_concat(ifnull(sc.transmissionCode, "")) from scannableCodes sc where sc.sku = p.sku) transmissionCodes
        from products p
        """

    func productBySku(_ dbQueue: DatabaseQueue, _ sku: String, _ shopId: String?) -> Product? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try self.fetchOne(db, ProductDB.productQuery + " where p.sku = ?", arguments: [sku])
            }
            return self.productFromRow(dbQueue, row, shopId)
        } catch {
            self.logError("productBySku db error: \(error)")
        }
        return nil
    }

    func productsBySku(_ dbQueue: DatabaseQueue, _ skus: [String], _ shopId: String?) -> [Product] {
        do {
            let list = skus.map { "\"\($0)\"" }.joined(separator: ",")
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, ProductDB.productQuery + " where p.sku in (\(list))")
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
        } catch {
            self.logError("productsBySku db error: \(error)")
        }
        return []
    }

    func boostedProducts(_ dbQueue: DatabaseQueue, limit: Int) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, ProductDB.productQuery + " " + """
                    where p.imageUrl is not null and p.boost > 0
                    order by p.boost desc
                    limit ?
                    """, arguments: [limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, nil) }
        } catch {
            self.logError("boostedProducts db error: \(error)")
        }
        return []
    }

    func discountedProducts(_ dbQueue: DatabaseQueue, _ shopId: String?) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, ProductDB.productQuery + " " + """
                    left outer join prices pr1 on pr1.sku = p.sku and pr1.pricingCategory = ifnull((select pricingCategory from shops where shops.id = ?), 0)
                    left outer join prices pr2 on pr2.sku = p.sku and pr2.pricingCategory = 0
                    where p.imageUrl is not null and ifnull(pr1.discountedPrice, pr2.discountedPrice) is not null
                    """, arguments: [shopId])
                }
            return rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
        } catch {
            self.logError("discountedProducts db error: \(error)")
        }
        return []
    }

    func productByScannableCode(_ dbQueue: DatabaseQueue, _ code: String, _ shopId: String?, retry: Bool = false) -> LookupResult? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try self.fetchOne(db, ProductDB.productQuery + " " + """
                    join scannableCodes s on s.sku = p.sku
                    where s.code = ?
                    """, arguments: [code])
                }
            if let product = self.productFromRow(dbQueue, row, shopId) {
                let transmissionCode = product.transmissionCodes[code]
                return LookupResult(product: product, code: transmissionCode)
            } else if !retry {
                // initial lookup failed

                // if it was an EAN-8, try again with the same EAN padded to an EAN-13
                // if it was an EAN-13 with a leading "0", try again with all leading zeroes removed
                if code.count == 8 {
                    Log.debug("8->13 lookup attempt \(code) -> 00000\(code)")
                    return self.productByScannableCode(dbQueue, "00000" + code, shopId, retry: true)
                } else if code.first == "0", let codeInt = Int(code) {
                    Log.debug("no leading zeroes db lookup attempt \(code) -> \(codeInt)")
                    return self.productByScannableCode(dbQueue, String(codeInt), shopId, retry: true)
                }
            }
        } catch {
            self.logError("productByScannableCode db error: \(error)")
        }

        return nil
    }

    func productByWeighItemId(_ dbQueue: DatabaseQueue, _ weighItemId: String, _ shopId: String?) -> Product? {
        do {
            let row = try dbQueue.inDatabase { db in
                return  try self.fetchOne(db, ProductDB.productQuery + " " + """
                    join weighItemIds w on w.sku = p.sku
                    where w.weighItemId = ?
                    """, arguments: [weighItemId])
            }
            return self.productFromRow(dbQueue, row, shopId)
        } catch {
            self.logError("productByWeighItemId db error: \(error)")
        }
        return nil
    }

    func productsByName(_ dbQueue: DatabaseQueue, _ name: String, _ filterDeposits: Bool) -> [Product] {
        do {
            let limit = name.count < 5 ? name.count * 100 : -1
            let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, ProductDB.productQuery + " " + """
                    where p.sku in (select sku from searchByName where foldedName match ? limit ?) \(depositCondition)
                    """, arguments: [name + "*", limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, nil) }
        } catch {
            self.logError("productsByName db error: \(error)")
        }
        return []
    }

    func productsByScannableCodePrefix(_ dbQueue: DatabaseQueue, _ prefix: String, _ filterDeposits: Bool) -> [Product] {
        do {
            let limit = 100 //  prefix.count < 5 ? prefix.count * 100 : -1
            let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, ProductDB.productQuery + " " + """
                    join scannableCodes s on s.sku = p.sku
                    where (s.code glob ? or s.code glob ?) \(depositCondition) and p.weighing != \(ProductType.preWeighed.rawValue)
                    limit ?
                    """, arguments: [prefix + "*", "00000" + prefix + "*", limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, nil) }
        } catch {
            self.logError("productByScannableCodePrefix db error: \(error)")
        }
        return []
    }

    func productsBundling(_ dbQueue: DatabaseQueue, _ sku: String, _ shopId: String?) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try self.fetchAll(db, ProductDB.productQuery + " " + """
                    where p.bundledSku = ?
                    """, arguments: [sku])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0, shopId) }
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
            try db.execute("drop table if exists searchByName_tmp")
            try db.execute("create virtual table searchByName_tmp using fts4(sku text, foldedname text)")

            let rows = try Row.fetchCursor(db, "select sku, name from products")

            try db.inTransaction {
                while let row = try rows.next() {
                    guard let sku = row["sku"] as? String, let name = row["name"] as? String else {
                        continue
                    }

                    let foldedName = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    try db.execute("insert into searchByName_tmp values(?, ?)", arguments: [ sku, foldedName ])
                }
                return .commit
            }

            try db.execute("drop table if exists searchByName")
            try db.execute("alter table searchByName_tmp rename to searchByName")
            try db.execute("vacuum")
        }
        let elapsed = Date.timeIntervalSinceReferenceDate - start
        Log.debug("update took \(elapsed)")
    }

    private func productFromRow(_ dbQueue: DatabaseQueue, _ row: Row?, _ shopId: String?) -> Product? {
        guard
            let row = row,
            let sku = row["sku"] as? String
        else {
            return nil
        }

        // if we have a shopId, get the price
        let priceRow: Row
        if let shopId = shopId, let pRow = self.getPriceRowForSku(dbQueue, sku, shopId) {
            priceRow = pRow
        } else {
            priceRow = row
        }

        // find deposit SKU
        let depositSku = row["depositSku"] as? String

        var depositPrice: Int?
        if let dSku = depositSku, let depositProduct = self.productBySku(dbQueue, dSku, shopId) {
            depositPrice = depositProduct.price
        }

        let bundles = self.productsBundling(dbQueue, sku, shopId)

        let (scannableCodes, transmissionCodes) = self.buildScannableCodeSets(row["scannableCodes"], row["transmissionCodes"])

        let p = Product(sku: sku,
                        name: row["name"],
                        description: row["description"],
                        subtitle: row["subtitle"],
                        imageUrl: row["imageUrl"],
                        basePrice: priceRow["basePrice"],
                        listPrice: priceRow["listPrice"],
                        discountedPrice: priceRow["discountedPrice"],
                        type: ProductType(rawValue: row["weighing"]) ?? .singleItem,
                        scannableCodes: scannableCodes,
                        weighedItemIds: self.makeSet(row["weighItemIds"]),
                        depositSku: depositSku,
                        bundledSku: row["bundledSku"],
                        isDeposit: row["isDeposit"] == 1,
                        deposit: depositPrice,
                        saleRestriction: SaleRestriction(row["saleRestriction"]),
                        saleStop: row["saleStop"] ?? false,
                        bundles: bundles,
                        transmissionCodes: transmissionCodes)

        return p
    }

    private func getPriceRowForSku(_ dbQueue: DatabaseQueue, _ sku: String, _ shopId: String) -> Row? {
        do {
            let row = try dbQueue.inDatabase { db in
                return  try self.fetchOne(db, """
                        select * from prices where pricingCategory = ifnull((select pricingCategory from shops where shops.id = ?), '0') and sku = ?
                        """, arguments: [shopId, sku])
            }
            if row != nil {
                return row
            }
            let row2 = try dbQueue.inDatabase { db in
                return  try self.fetchOne(db, """
                        select * from prices where pricingCategory = 0) and sku = ?
                        """, arguments: [sku])
            }
            return row2
        } catch {
            self.logError("getPriceRowForSku db error: \(error)")
        }
        return nil
    }

    private func buildScannableCodeSets(_ rawScan: String?, _ rawTransmit: String?) -> (Set<String>, [String:String]) {
        guard let rawScan = rawScan, let rawTransmit = rawTransmit else {
            return (Set<String>(), [:])
        }

        let codes = rawScan.components(separatedBy: ",")
        let transmit = rawTransmit.components(separatedBy: ",")

        var codeMap = [String: String]()
        for (code, xmit) in zip(codes, transmit) {
            if xmit.count > 0 {
                codeMap[code] = xmit
            }
        }

        return (Set(codes), codeMap)
    }

    private func makeSet(_ str: String?) -> Set<String> {
        guard let s = str else {
            return Set([])
        }
        return Set(s.components(separatedBy: ","))
    }

    // timing-logging wrappers around Row.fecthOne/fetchAll

    private func fetchOne(_ db: Database, _ query: String, arguments: StatementArguments? = nil) throws -> Row? {
        let start = Date.timeIntervalSinceReferenceDate
        defer {
            self.logSlowQuery(db, query, arguments, start)
        }
        return try Row.fetchOne(db, query, arguments: arguments, adapter: nil)
    }

    private func fetchAll(_ db: Database, _ query: String, arguments: StatementArguments? = nil) throws -> [Row] {
        let start = Date.timeIntervalSinceReferenceDate
        defer {
            self.logSlowQuery(db, query, arguments, start)
        }
        return try Row.fetchAll(db, query, arguments: arguments, adapter: nil)
    }

    private func logSlowQuery(_ db: Database, _ query: String, _ arguments: StatementArguments?, _ start: TimeInterval) {
        let elapsed = Date.timeIntervalSinceReferenceDate - start

        if _isDebugAssertConfiguration() && elapsed >= 0.01 {
            Log.info("slow query: \(elapsed)s for \(query) - arguments: \(String(describing: arguments))" )
            self.queryPlan(db, query, arguments)
        }
    }

    private func queryPlan(_ db: Database, _ query: String, _ arguments: StatementArguments?) {
        do {
            for explain in try Row.fetchAll(db, "EXPLAIN QUERY PLAN " + query, arguments: arguments) {
                Log.debug("EXPLAIN: \(explain)")
            }
        } catch {
            Log.error("query explain error \(error)")
        }
    }
}
