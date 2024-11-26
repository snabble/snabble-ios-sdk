//
//  SnabbleTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest

@testable import SnabbleCore

class SnabbleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDB() {
        let testingSecret = "J4P3KBTJONMI2EOAA3DHMKWIYQCME3UF7UC2LGLHYU2BUCE6QR4Q===="

        var config = Config(appId: "test-app-xetha3",
                            secret: testingSecret,
                            environment: .testing)
        config.useFTS = true
        config.seedDatabase = Bundle.module.path(forResource: "testseed", ofType: "zip")
        config.seedRevision = 1
        config.seedMetadata = Bundle.module.path(forResource: "seedIndex", ofType: "json")

        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dbPath = appSupportDir.appendingPathComponent("test-ieme8a", isDirectory: true).appendingPathComponent("products.sqlite3")

        URLCache.shared.removeAllCachedResponses()

        if FileManager.default.fileExists(atPath: dbPath.path) {
            try? FileManager.default.removeItem(at: dbPath)
        }

        let expectation = self.expectation(description: "run async tests")
        expectation.expectedFulfillmentCount = 12
        expectation.assertForOverFulfill = true

        Snabble.setup(config: config) { snabble in
            snabble.appUser = nil
            self.runDbTests(expectation)
        }

        self.wait(for: [expectation], timeout: 30)
    }

    private func runDbTests(_ expectation: XCTestExpectation) {
        let links = ProjectLinks(appdb: Link(href: "/test-ieme8a/appdb"),
                                 appEvents: Link.empty,
                                 checkoutInfo: Link.empty,
                                 tokens: Link(href: "/test-ieme8a/tokens"),
                                 resolvedProductBySku: Link(href: "/test-ieme8a/resolvedProducts/sku/{sku}"),
                                 resolvedProductLookUp: Link(href: "/test-ieme8a/resolvedProducts/lookUp"))
        let testProject = Project("test-ieme8a", links: links)
        let productProvider = Snabble.shared.productProvider(for: testProject)
        
        let productStore = Snabble.shared.productStore(for: testProject)
        productStore.setup(update: .never, forceFullDownload: false, completion: { _ in })

        NSLog("start db tests")
        let shopId: Identifier<Shop> = "8"

        XCTAssertNil(productProvider.productBy(sku: "1234", shopId: shopId), "unexpected product found")
        XCTAssertNotNil(productProvider.productBy(sku: "22", shopId: shopId), "sku 22 not found")

        var products = productProvider.productsBy(skus: ["1234","5678"], shopId: shopId)
        XCTAssertEqual(products.count, 0, "unexpected product found")
        products = productProvider.productsBy(skus: ["22","23"], shopId: shopId)
        XCTAssertEqual(products.count, 2, "skus 22+23 not found")

        XCTAssertNil(productProvider.scannedProductBy(codes: [("1234", "default")], shopId: shopId), "unexpected product found")
        XCTAssertNotNil(productProvider.scannedProductBy(codes: [("0885580466671", "default")], shopId: shopId), "ean 0885580466671 not found")

        XCTAssertNotNil(productProvider.scannedProductBy(codes: [("0885580466671", "default"), ("0885580466671", "ean13_instore"), ("0885580466671", "ean13_instore_chk") ], shopId: shopId), "ean 0885580466671 not found")

        XCTAssertNotNil(productProvider.scannedProductBy(codes: [("32323", "ean13_instore_chk")], shopId: shopId), "weightItem XYZ not found")

        let hoodies = productProvider.productsByName("hoodie")
        XCTAssertTrue(hoodies.count > 0, "no hoodies found")
        if hoodies.count > 0 {
            XCTAssertNotNil(productProvider.productBy(sku: hoodies[0].sku, shopId: shopId), "sku lookup fail")
            XCTAssertNotNil(productProvider.scannedProductBy(codes: [(hoodies[0].codes.first!.code, "default")], shopId: shopId), "ean lookup fail")
        }

        // check for codes beginning with 4 - there should be some
        let prefix4 = productProvider.productsBy(prefix: "4", shopId: "")
        XCTAssertTrue(prefix4.count > 0, "ean prefix fail")

        // check for codes beginning with 5 - there should be none, due to records in `availabilities`
        let prefix5 = productProvider.productsBy(prefix: "5", shopId: "").filter { !$0.sku.hasPrefix("5") }
        XCTAssertEqual(prefix5.count, 0, "ean prefix fail")

        let prod = productProvider.productBy(sku: "50", shopId: shopId)
        XCTAssertNotNil(prod)
        XCTAssertEqual(prod?.codes.count, 2)

        let prod1 = productProvider.scannedProductBy(codes: [("40084015", "default")], shopId: shopId)
        XCTAssertNotNil(prod1)
        XCTAssertEqual(prod1?.product.codes.count, 2)
        XCTAssertEqual(prod1?.transmissionCode, nil)

        let prod2 = productProvider.scannedProductBy(codes: [("0000040084015", "default")], shopId: shopId)
        XCTAssertNotNil(prod2)
        XCTAssertEqual(prod2?.product.codes.count, 2)
        XCTAssertEqual(prod2?.transmissionCode, "40084015")

        productProvider.productBy(sku: "22", shopId: shopId, forceDownload: true) { result in
            self.assertOk(result, "d/l product by sku failed")
            expectation.fulfill()
        }

        productProvider.productBy(sku: "1234", shopId: shopId, forceDownload: true) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

        productProvider.productBy(codes: [("0885580466671", "default")], shopId: shopId) { result in
            self.assertOk(result, "d/l product by ean failed")
            expectation.fulfill()
        }

        productProvider.productBy(codes: [("1234", "default")], shopId: shopId) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

        productProvider.scannedProductBy(codes: [("0885580466671", "default")], shopId: shopId, forceDownload: true) { result in
            self.assertOk(result, "d/l product by ean failed")
            expectation.fulfill()
        }

        productProvider.scannedProductBy(codes: [("0885580466671", "default"),("0885580466671", "ean13_instore"),("0885580466671", "ean13_instore_chk")], shopId: shopId, forceDownload: true) { result in
            self.assertOk(result, "d/l product by ean failed")
            expectation.fulfill()
        }

        productProvider.scannedProductBy(codes: [("1234", "default")], shopId: shopId, forceDownload: true) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

//        pdb.productBy(codes: [("32323", "ean13_instore_chk")], shopId, forceDownload: true) { result in
//            self.assertOk(result, "d/l product by weighId failed")
//            expectation.fulfill()
//        }

        productProvider.scannedProductBy(codes: [("1234", "ean13_instore_chk")], shopId: shopId, forceDownload: true) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

        productProvider.productBy(sku: "37", shopId: shopId, forceDownload: false) { result in
            self.assertOk(result, "no product")
            switch result {
            case .success(let product):
                XCTAssertGreaterThan(product.bundles.count, 0)
                for p in product.bundles {
                    XCTAssertNotNil(p.deposit)
                    XCTAssertGreaterThan(p.deposit!, 0)
                }
            default: ()
            }
            expectation.fulfill()
        }

        productProvider.productBy(sku: "37", shopId: shopId, forceDownload: true) { result in
            self.assertOk(result, "no product")
            switch result {
            case .success(let product):
                XCTAssertGreaterThan(product.bundles.count, 0)
                for p in product.bundles {
                    XCTAssertNotNil(p.deposit)
                    XCTAssertGreaterThan(p.deposit!, 0)
                }
            case .failure: ()
            }
            expectation.fulfill()
        }

        productProvider.productBy(sku: "salfter-classic", shopId: "177", forceDownload: true) { result in
            self.assertOk(result, "no product")
            switch result {
            case .success(let product):
                XCTAssertEqual(product.price(nil), 100)
            case .failure: ()
            }
            expectation.fulfill()
        }

        productProvider.productBy(sku: "salfter-classic", shopId: "1775", forceDownload: true) { result in
            self.assertOk(result, "no product")
            switch result {
            case .success(let product):
                XCTAssertEqual(product.price(nil), 100)
            case .failure: ()
            }
            expectation.fulfill()
        }


        NSLog("db tests done")
    }

    func assertOk<Success,Failure>(_ result: Result<Success,Failure>, _ message: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNoThrow(try result.get(), message, file: file, line: line)
    }

    func assertError<Success,Failure>(_ result: Result<Success,Failure>, _ message: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertThrowsError(try result.get(), message, file: file, line: line)
    }
}
