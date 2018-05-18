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
            (select group_concat(w.weighItemId) from weighItemIds w where w.sku = p.sku) weighItemIds
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
            let list = skus.map { String($0) }.joined(separator: ",")
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

    func productByScannableCode(_ dbQueue: DatabaseQueue, _ code: String) -> Product? {
        do {
            let row = try dbQueue.inDatabase { db in
                return try Row.fetchOne(db, ProductDB.baseQuery + " " + """
                    join scannableCodes s on s.sku = p.sku
                    where s.code = ?
                    """, arguments: [code])
                }
            return self.productFromRow(dbQueue, row)
        } catch {
            NSLog("db error: \(error)")
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
                    where p.sku in (select docid from searchByName where foldedName match ? limit ?) \(depositCondition)
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

    private func productFromRow(_ dbQueue: DatabaseQueue, _ row: Row?) -> Product? {
        guard let row = row else {
            return nil
        }

        // find SKU
        let sku: String
        if let intSku = row["sku"] as? Int64 {
            sku = String(intSku)
        } else if let strSku = row["sku"] as? String {
            sku = strSku
        } else {
            return nil
        }

        // find deposit SKU
        let depositSku: String?
        if let dSku = row["depositSku"] as? Int64 {
            depositSku = String(dSku)
        } else if let dSku = row["depositSku"] as? String {
            depositSku = dSku
        } else {
            depositSku = nil
        }

        var depositPrice: Int?
        if let dSku = depositSku, let depositProduct = self.productBySku(dbQueue, dSku) {
            depositPrice = depositProduct.price
        }

        let p = Product(sku: sku,
                        name: row["name"],
                        description: row["description"],
                        subtitle: row["subtitle"],
                        imageUrl: row["imageUrl"],
                        basePrice: row["basePrice"],
                        listPrice: row["listPrice"],
                        discountedPrice: row["discountedPrice"],
                        type: ProductType(rawValue: row["weighing"]) ?? .singleItem,
                        scannableCodes: makeSet(row["scannableCodes"]),
                        weighedItemIds: makeSet(row["weighIds"]),
                        depositSku: depositSku,
                        isDeposit: row["isDeposit"] == 1,
                        deposit: depositPrice,
                        saleRestriction: self.decodeSaleRestriction(row["saleRestriction"]),
                        saleStop: row["saleStop"] ?? false)

        return p
    }

    private func makeSet(_ str: String?) -> Set<String> {
        guard let s = str else {
            return Set([])
        }
        return Set(s.components(separatedBy: ","))
    }

    private func decodeSaleRestriction(_ code: Int64?) -> SaleRestriction {
        guard let code = code else {
            return .none
        }

        let type = code & 0xFF
        if type == 1 { // age
            let age = (code & 0xFF00) >> 8
            return .age(Int(age))
        }

        return .none
    }
}
