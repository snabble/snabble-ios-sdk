//
//  ProductDB+Queries.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation
import GRDB


// MARK: - low-level db queries
extension ProductDB {

    static let baseQuery = """
        select
            p.*, pr.listPrice, pr.discountedPrice, pr.basePrice,
            (select group_concat(sc.code) from scannableCodes sc where sc.sku = p.sku) scannableCodes,
            (select group_concat(w.weighItemId) from weighItemIds w where w.sku = p.sku) weighItemIds,
            (SELECT group_concat(ifnull(sc.transmissionCode, "")) FROM scannableCodes sc WHERE sc.sku = p.sku) transmissionCodes
        from products p
        join prices pr on pr.sku = p.sku
    """

    func productBySku(_ dbQueue: DatabaseQueue, _ sku: String) -> Product? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try Row.fetchOne(db, ProductDB.baseQuery + " where p.sku = ?", arguments: [sku])
            }
            return self.productFromRow(dbQueue, row)
        } catch {
            NSLog("db error: \(error)")
        }
        return nil
    }

    func productsBySku(_ dbQueue: DatabaseQueue, _ skus: [String]) -> [Product] {
        do {
            let list = skus.map { "\"\($0)\"" }.joined(separator: ",")
            let rows = try dbQueue.inDatabase { db in
                return try Row.fetchAll(db, ProductDB.baseQuery + " where p.sku in (\(list))")
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0) }
        } catch {
            NSLog("db error: \(error)")
        }
        return []
    }

    func boostedProducts(_ dbQueue: DatabaseQueue, limit: Int) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try Row.fetchAll(db, ProductDB.baseQuery + " " + """
                    where p.imageUrl is not null and p.boost > 0
                    order by p.boost desc
                    limit ?
                    """, arguments: [limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0) }
        } catch {
            NSLog("db error: \(error)")
        }
        return []
    }

    func discountedProducts(_ dbQueue: DatabaseQueue) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try Row.fetchAll(db, ProductDB.baseQuery + " " + """
                    where p.imageUrl is not null and pr.discountedPrice is not null
                    group by p.sku
                    """)
                }
            return rows.compactMap { self.productFromRow(dbQueue, $0) }
        } catch {
            NSLog("db error: \(error)")
        }
        return []
    }

    func productByScannableCode(_ dbQueue: DatabaseQueue, _ code: String) -> LookupResult? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try Row.fetchOne(db, ProductDB.baseQuery + " " + """
                    join scannableCodes s on s.sku = p.sku
                    where s.code = ?
                    """, arguments: [code])
                }
            if let product = self.productFromRow(dbQueue, row) {
                let transmissionCode = product.transmissionCodes[code] ?? code
                return LookupResult(product: product, code: transmissionCode)
            } else {
                // lookup failed. if it was an EAN-8, try again with the same EAN padded to an EAN-13
                if code.count == 8 {
                    print("8->13 lookup attempt \(code) -> 00000\(code)")
                    return self.productByScannableCode("00000" + code)
                }
            }
        } catch {
            NSLog("db error: \(error)")
        }

        if code.first == "0", let codeInt = Int(code) {
            // no product found. try the lookup again, with all leading zeroes removed from `code`
            print("2nd db lookup attempt \(code) -> \(codeInt)")
            return self.productByScannableCode(dbQueue, String(codeInt))
        }
        return nil
    }

    func productByWeighItemId(_ dbQueue: DatabaseQueue, _ weighItemId: String) -> Product? {
        do {
            let row = try dbQueue.inDatabase { db in
                return  try Row.fetchOne(db, ProductDB.baseQuery + " " + """
                    join weighItemIds w on w.sku = p.sku
                    where w.weighItemId = ?
                    """, arguments: [weighItemId])
            }
            return self.productFromRow(dbQueue, row)
        } catch {
            NSLog("db error: \(error)")
        }
        return nil
    }

    func productsByName(_ dbQueue: DatabaseQueue, _ name: String, _ filterDeposits: Bool) -> [Product] {
        do {
            let limit = name.count < 5 ? name.count * 100 : -1
            let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
            let rows = try dbQueue.inDatabase { db in
                return try Row.fetchAll(db, ProductDB.baseQuery + " " + """
                    where p.sku in (select sku from searchByName where foldedName match ? limit ?) \(depositCondition)
                    """, arguments: [name + "*", limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0) }
        } catch {
            NSLog("db error: \(error)")
        }
        return []
    }

    func productsByScannableCodePrefix(_ dbQueue: DatabaseQueue, _ prefix: String, _ filterDeposits: Bool) -> [Product] {
        do {
            let limit = prefix.count < 5 ? prefix.count * 100 : -1
            let depositCondition = filterDeposits ? "and isDeposit = 0" : ""
            let rows = try dbQueue.inDatabase { db in
                return try Row.fetchAll(db, ProductDB.baseQuery + " " + """
                    join scannableCodes s on s.sku = p.sku
                    where s.code glob ? \(depositCondition) and p.weighing != \(ProductType.preWeighed.rawValue)
                    limit ?
                    """, arguments: [prefix + "*", limit])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0) }
        } catch {
            NSLog("db error: \(error)")
        }
        return []
    }

    func productsBundling(_ dbQueue: DatabaseQueue, _ sku: String) -> [Product] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try Row.fetchAll(db, ProductDB.baseQuery + " " + """
                    where p.bundledSku = ?
                    """, arguments: [sku])
            }
            return rows.compactMap { self.productFromRow(dbQueue, $0) }
        } catch {
            NSLog("db error: \(error)")
        }
        return []
    }

    func metadata(_ dbQueue: DatabaseQueue) -> [String: String] {
        do {
            let rows = try dbQueue.inDatabase { db in
                return try Row.fetchAll(db, "select * from metadata")
            }

            let tuples = rows.compactMap { ($0["key"], $0["value"]) as? (String, String) }
            return Dictionary(uniqueKeysWithValues: tuples)
        } catch {
            NSLog("db error: \(error)")
        }
        return [:]
    }

    func createFullTextIndex(_ dbQueue: DatabaseQueue) throws {
        let start = Date.timeIntervalSinceReferenceDate
        try dbQueue.write { db in
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
        print("update took \(elapsed)")
    }


    private func productFromRow(_ dbQueue: DatabaseQueue, _ row: Row?) -> Product? {
        guard
            let row = row,
            let sku = row["sku"] as? String
        else {
            return nil
        }

        // find deposit SKU
        let depositSku = row["depositSku"] as? String

        var depositPrice: Int?
        if let dSku = depositSku, let depositProduct = self.productBySku(dbQueue, dSku) {
            depositPrice = depositProduct.price
        }

        let bundles = self.productsBundling(dbQueue, sku)

        let (scannableCodes, transmissionCodes) = self.buildScannableCodeSets(row["scannableCodes"], row["transmissionCodes"])

        let p = Product(sku: sku,
                        name: row["name"],
                        description: row["description"],
                        subtitle: row["subtitle"],
                        imageUrl: row["imageUrl"],
                        basePrice: row["basePrice"],
                        listPrice: row["listPrice"],
                        discountedPrice: row["discountedPrice"],
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

    
}
