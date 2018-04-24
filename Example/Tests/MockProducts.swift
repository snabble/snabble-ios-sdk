//
//  MockProducts.swift
//  Snabble
//
//  Copyright © 2018 snabble GmbH. All rights reserved.
//

import Foundation
@testable import Snabble

class MockProductDB: ProductProvider {

    let prod1 = Product(sku: "1",
                        name: "product 1",
                        description: "description 1",
                        subtitle: "subtitle 1",
                        imageUrl: nil,
                        basePrice: "1€/kg",
                        listPrice: 100,
                        discountedPrice: nil,
                        type: .singleItem,
                        eans: Set(["ean1"]),
                        weighedItemIds: nil,
                        depositSku: nil,
                        isDeposit: false,
                        deposit: nil)

    let prod2 = Product(sku: "2",
                        name: "product 2",
                        description: "description 2",
                        subtitle: "subtitle 2",
                        imageUrl: nil,
                        basePrice: "2€/kg",
                        listPrice: 200,
                        discountedPrice: nil,
                        type: .singleItem,
                        eans: Set(["ean1"]),
                        weighedItemIds: nil,
                        depositSku: nil,
                        isDeposit: false,
                        deposit: nil)

    var map = [String: Product]()

    required init(_ config: ProductDBConfiguration) {
        map[prod1.sku] = prod1
        map[prod2.sku] = prod2
    }

    func setup(completion: @escaping ((Bool) -> ())) {}

    func updateDatabase(completion: @escaping (Bool) -> ()) {}

    func productBySku(_ sku: String) -> Product? {
        return map[sku]
    }

    func productsBySku(_ skus: [String]) -> [Product] {
        return []
    }

    func boostedProducts(limit: Int) -> [Product] {
        return []
    }

    func discountedProducts() -> [Product] {
        return []
    }

    func productByEan(_ ean: String) -> Product? {
        return nil
    }

    func productByWeighItemId(_ weighItemId: String) -> Product? {
        return nil
    }

    func productsByName(_ name: String) -> [Product] {
        return []
    }

    func productsByEanPrefix(_ eanPrefix: String) -> [Product] {
        return []
    }

}
