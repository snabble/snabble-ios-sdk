//
//  ProductDatabase+Mapping.swift
//  
//
//  Created by Uwe Tilemann on 23.10.22.
//

import Foundation
import GRDB

extension Product {
    
    struct Deposit {
        let sku: String?
        let price: Int?
    }
    
    struct ProductUnits {
        let reference: Units?
        let encoding: Units?
        
        init(row: Row) {
            self.reference = Units.from(row["referenceUnit"] as? String)
            var encodingUnit = Units.from(row["encodingUnit"] as? String)
            if let encodingOverride = Units.from(row["code_encodingUnit"] as? String) {
                encodingUnit = encodingOverride
            }
            self.encoding = encodingUnit
        }
    }

    struct MappingValues {
        let sku: String
        let deposit: Deposit
        let bundles: [Product]
        let codes: [ScannableCode]
        let units: ProductUnits
        
        init(sku: String, bundles: [Product] = [], codes: [ScannableCode] = [], deposit: Deposit, units: ProductUnits) {
            self.sku = sku
            self.bundles = bundles
            self.codes = codes
            self.deposit = deposit
            self.units = units
        }
        
        init(sku: String, row: Row, bundles: [Product] = [], deposit: Deposit) {
            let codes = Product.buildCodes(row)
            let units = ProductUnits(row: row)

            self.init(sku: sku, bundles: bundles, codes: codes, deposit: deposit, units: units)
        }
    }
    
    static func map(productRow row: Row, priceRow: Row, values: MappingValues) -> Product {
        return Product(sku: values.sku,
                       name: row["name"],
                       description: row["description"],
                       subtitle: row["subtitle"],
                       imageUrl: row["imageUrl"],
                       basePrice: priceRow["basePrice"],
                       listPrice: priceRow["listPrice"],
                       discountedPrice: priceRow["discountedPrice"],
                       customerCardPrice: priceRow["customerCardPrice"],
                       type: ProductType(rawValue: row["weighing"]),
                       codes: values.codes,
                       depositSku: values.deposit.sku,
                       bundledSku: row["bundledSku"],
                       isDeposit: row["isDeposit"] == 1,
                       deposit: values.deposit.price,
                       saleRestriction: SaleRestriction(row["saleRestriction"]),
                       saleStop: row["saleStop"] ?? false,
                       bundles: values.bundles,
                       referenceUnit: values.units.reference,
                       encodingUnit: values.units.encoding,
                       scanMessage: row["scanMessage"],
                       availability: ProductAvailability(rawValue: row["availability"]),
                       notForSale: row["notForSale"] ?? false)
    }
    
    static func buildCodes(_ row: Row) -> [ScannableCode] {
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
}
