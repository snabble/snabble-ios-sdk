//
//  MockProducts.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleCore

class MockProductDB: ProductStoring & ProductProviding {
    var supportFulltextSearch: Bool {
        return true
    }
    
    var isUpToDate: Bool {
        return true
    }
    
    var productAvailability: SnabbleCore.ProductAvailability = .inStock
    var database: AnyObject? = nil
    var databasePath: String = "empty"
    
    var databaseExists: Bool {
        return false
    }

    var schemaVersionMajor = 1
    var schemaVersionMinor = 0
    var revision: Int64 = 0

    var lastUpdate = Date()
    var availability = ProductStoreAvailability.unknown

    static let p1 = Product(sku: "1",
                        name: "product 1",
                        description: "description 1",
                        subtitle: "subtitle 1",
                        imageUrl: nil,
                        basePrice: "1€/kg",
                        listPrice: 100,
                        discountedPrice: nil,
                        type: .singleItem,
                        codes: [])

    static let p2 = Product(sku: "2",
                        name: "product 2",
                        description: "description 2",
                        subtitle: "subtitle 2",
                        imageUrl: nil,
                        basePrice: "2€/kg",
                        listPrice: 200,
                        discountedPrice: 150,
                        type: .singleItem,
                        codes: [])

    static let p3 = Product(sku: "3",
                     name: "product 3",
                     description: "description 3",
                     subtitle: "subtitle 3",
                     imageUrl: nil,
                     basePrice: nil,
                     listPrice: 200,
                     type: .singleItem,
                     codes: [],
                     depositSku: "3",
                     deposit: 15)

    static let p4 = Product(sku: "4",
                     name: "product 4 (deposit)",
                     description: "description 4",
                     subtitle: "subtitle 4",
                     imageUrl: nil,
                     basePrice: "2€/kg",
                     listPrice: 15,
                     type: .singleItem,
                     codes: [])

    static let p5 = Product(sku: "5",
                            name: "product 5 (weigh)",
                            description: "description 5",
                            subtitle: "subtitle 5",
                            basePrice: "2€/kg",
                            listPrice: 1234,
                            type: .preWeighed,
                            codes: [],
                            isDeposit: true,
                            referenceUnit: .kilogram,
                            encodingUnit: .gram)

    static let p6 = Product(sku: "6",
                            name: "product 6 (weigh)",
                            description: "description 6",
                            subtitle: "subtitle 6",
                            basePrice: "200€/m3",
                            listPrice: 20000,
                            type: .preWeighed,
                            codes: [],
                            referenceUnit: .cubicMeter,
                            encodingUnit: .cubicCentimeter)

    static let p7 = Product(sku: "7",
                            name: "product 7",
                            description: "description 7",
                            subtitle: "subtitle 7",
                            imageUrl: nil,
                            basePrice: "2€/kg",
                            listPrice: 200,
                            discountedPrice: 150,
                            customerCardPrice: 120,
                            type: .singleItem,
                            codes: [])

    nonisolated(unsafe) private static var productMap = [String: Product]()
    private static let allProducts = [p1, p2, p3, p4, p5]

    required init(_ config: Config, _ project: Project) {
        MockProductDB.allProducts.forEach {
            MockProductDB.productMap[$0.sku] = $0
        }
    }

    func setup(update: ProductDbUpdate = .always, forceFullDownload: Bool = false, completion: @escaping ((ProductStoreAvailability) -> ())) { }

    func updateDatabase(forceFullDownload: Bool = false, completion: @escaping (ProductStoreAvailability) -> ()) {}

    func resumeIncompleteUpdate(completion: @escaping (ProductStoreAvailability) -> ()) {}

    func stopDatabaseUpdate() {}

    func productBy(sku: String, shopId: Identifier<Shop>) -> Product? {
        return MockProductDB.productMap[sku]
    }

    func scannedProductBy(codes: [(String, String)], shopId: Identifier<Shop>) -> ScannedProduct? {
        return nil
    }

    func productsBy(skus: [String], shopId: Identifier<Shop>) -> [Product] {
        var products = [Product]()
        skus.forEach {
            if let p = MockProductDB.productMap[$0] {
                products.append(p)
            }
        }
        return products
    }

    func productsBy(name: String, filterDeposits: Bool) -> [Product] {
        let products = MockProductDB.allProducts.filter { $0.name.contains(name) }
        return products
    }

    func productsBy(prefix: String, filterDeposits: Bool, templates: [String]?, shopId: Identifier<Shop>) -> [Product] {
        let products = MockProductDB.allProducts.filter { product in
            let matches = product.codes.filter { $0.template == "default" && $0.code.hasPrefix(prefix) }
            return matches.count > 0
        }
        if filterDeposits {
            return products.filter { !$0.isDeposit }
        } else {
            return products
        }
    }

    func productBy(sku: String, shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<Product, ProductLookupError>) -> ()) {
        completion(Result.failure(.notFound))
    }

    func scannedProductBy(codes: [(String, String)], shopId: Identifier<Shop>, forceDownload: Bool, completion: @escaping (Result<ScannedProduct, ProductLookupError>) -> ()) {
        completion(Result.failure(.notFound))
    }

}

class ProductTests: XCTestCase {
    func testPrice() {
        let product = MockProductDB.p7

        XCTAssertEqual(product.listPrice, 200)
        XCTAssertEqual(product.price(nil), 150)
        XCTAssertEqual(product.price("4711"), 120)
    }
}
