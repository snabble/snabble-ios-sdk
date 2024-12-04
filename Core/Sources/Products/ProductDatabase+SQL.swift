//
//  ProductDatabase+SQL.swift
//  
//
//  Created by Uwe Tilemann on 23.10.22.
//

import Foundation
import GRDB

// MARK: - SQL Statements
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
