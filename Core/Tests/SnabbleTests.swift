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
            snabble.appUserId = nil
            self.runDbTests(expectation)
        }

        self.wait(for: [expectation], timeout: 15)
    }

    private func runDbTests(_ expectation: XCTestExpectation) {
        let links = ProjectLinks(appdb: Link(href: "/test-ieme8a/appdb"),
                                 appEvents: Link.empty,
                                 checkoutInfo: Link.empty,
                                 tokens: Link(href: "/test-ieme8a/tokens"),
                                 resolvedProductBySku: Link(href: "/test-ieme8a/resolvedProducts/sku/{sku}"),
                                 resolvedProductLookUp: Link(href: "/test-ieme8a/resolvedProducts/lookUp"))
        let testProject = Project("test-ieme8a", links: links)
        let pdb = Snabble.shared.productProvider(for: testProject)
        pdb.setup(update: .never, forceFullDownload: false, completion: { _ in })

        NSLog("start db tests")
        let shopId: Identifier<Shop> = "8"

        XCTAssertNil(pdb.productBySku("1234", shopId), "unexpected product found")
        XCTAssertNotNil(pdb.productBySku("22", shopId), "sku 22 not found")

        var products = pdb.productsBySku(["1234","5678"], shopId)
        XCTAssertEqual(products.count, 0, "unexpected product found")
        products = pdb.productsBySku(["22","23"], shopId)
        XCTAssertEqual(products.count, 2, "skus 22+23 not found")

        XCTAssertNil(pdb.productByScannableCodes([("1234", "default")], shopId), "unexpected product found")
        XCTAssertNotNil(pdb.productByScannableCodes([("0885580466671", "default")], shopId), "ean 0885580466671 not found")

        XCTAssertNotNil(pdb.productByScannableCodes([("0885580466671", "default"), ("0885580466671", "ean13_instore"), ("0885580466671", "ean13_instore_chk") ], shopId), "ean 0885580466671 not found")

        XCTAssertNotNil(pdb.productByScannableCodes([("32323", "ean13_instore_chk")], shopId), "weightItem XYZ not found")

        let hoodies = pdb.productsByName("hoodie")
        XCTAssertTrue(hoodies.count > 0, "no hoodies found")
        if hoodies.count > 0 {
            XCTAssertNotNil(pdb.productBySku(hoodies[0].sku, shopId), "sku lookup fail")
            XCTAssertNotNil(pdb.productByScannableCodes([(hoodies[0].codes.first!.code, "default")], shopId), "ean lookup fail")
        }

        // check for codes beginning with 4 - there should be some
        let prefix4 = pdb.productsByScannableCodePrefix("4", "")
        XCTAssertTrue(prefix4.count > 0, "ean prefix fail")

        // check for codes beginning with 5 - there should be none, due to records in `availabilities`
        let prefix5 = pdb.productsByScannableCodePrefix("5", "").filter { !$0.sku.hasPrefix("5") }
        XCTAssertEqual(prefix5.count, 0, "ean prefix fail")

        let prod = pdb.productBySku("50", shopId)
        XCTAssertNotNil(prod)
        XCTAssertEqual(prod?.codes.count, 2)

        let prod1 = pdb.productByScannableCodes([("40084015", "default")], shopId)
        XCTAssertNotNil(prod1)
        XCTAssertEqual(prod1?.product.codes.count, 2)
        XCTAssertEqual(prod1?.transmissionCode, nil)

        let prod2 = pdb.productByScannableCodes([("0000040084015", "default")], shopId)
        XCTAssertNotNil(prod2)
        XCTAssertEqual(prod2?.product.codes.count, 2)
        XCTAssertEqual(prod2?.transmissionCode, "40084015")

        pdb.productBySku("22", shopId, forceDownload: true) { result in
            self.assertOk(result, "d/l product by sku failed")
            expectation.fulfill()
        }

        pdb.productBySku("1234", shopId, forceDownload: true) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

        pdb.productByScannableCodes([("0885580466671", "default")], shopId) { result in
            self.assertOk(result, "d/l product by ean failed")
            expectation.fulfill()
        }

        pdb.productByScannableCodes([("1234", "default")], shopId) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

        pdb.productByScannableCodes([("0885580466671", "default")], shopId, forceDownload: true) { result in
            self.assertOk(result, "d/l product by ean failed")
            expectation.fulfill()
        }

        pdb.productByScannableCodes([("0885580466671", "default"),("0885580466671", "ean13_instore"),("0885580466671", "ean13_instore_chk")], shopId, forceDownload: true) { result in
            self.assertOk(result, "d/l product by ean failed")
            expectation.fulfill()
        }

        pdb.productByScannableCodes([("1234", "default")], shopId, forceDownload: true) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

//        pdb.productByScannableCodes([("32323", "ean13_instore_chk")], shopId, forceDownload: true) { result in
//            self.assertOk(result, "d/l product by weighId failed")
//            expectation.fulfill()
//        }

        pdb.productByScannableCodes([("1234", "ean13_instore_chk")], shopId, forceDownload: true) { result in
            self.assertError(result, "unexpected product")
            expectation.fulfill()
        }

        pdb.productBySku("37", shopId, forceDownload: false) { result in
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

        pdb.productBySku("37", shopId, forceDownload: true) { result in
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

        pdb.productBySku("salfter-classic", "177", forceDownload: true) { result in
            self.assertOk(result, "no product")
            switch result {
            case .success(let product):
                XCTAssertEqual(product.price(nil), 100)
            case .failure: ()
            }
            expectation.fulfill()
        }

        pdb.productBySku("salfter-classic", "1775", forceDownload: true) { result in
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
