import UIKit
import XCTest
@testable import Snabble

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEAN13() {
        // fake EANs
        XCTAssertNotNil(EAN13("2001234000000"))
        XCTAssertNil(EAN13("2001234000001"))

        // Club Mate 0.5l
        XCTAssertNil(EAN13("4029764001801"))
        XCTAssertNil(EAN13("4029764001802"))
        XCTAssertNil(EAN13("4029764001803"))
        XCTAssertNil(EAN13("4029764001804"))
        XCTAssertNil(EAN13("4029764001805"))
        XCTAssertNil(EAN13("4029764001806"))
        XCTAssertNotNil(EAN13("4029764001807"))
        XCTAssertNil(EAN13("4029764001808"))
        XCTAssertNil(EAN13("4029764001809"))
        XCTAssertNil(EAN13("4029764001800"))
        XCTAssertEqual(EAN13.checkDigit(for: "4029764001807"), 7)
        XCTAssertEqual(EAN13.checkDigit(for: "4029764001805"), 7)

        // test 12-digit codes
        XCTAssertEqual(EAN13.checkDigit(for: "200123400000"), 0)
        XCTAssertEqual(EAN13.checkDigit(for: "200123500129"), 7)
        XCTAssertEqual(EAN13.checkDigit(for: "629104150021"), 3)
        XCTAssertEqual(EAN13.checkDigit(for: "222111100000"), 2)
        XCTAssertEqual(EAN13.checkDigit(for: "222111200000"), 1)

        // test failures
        XCTAssertNil(EAN13(""))
        XCTAssertNil(EAN13("1234567890"))
        XCTAssertNil(EAN13("1234567890A"))
        XCTAssertNil(EAN13("1234567890123"))
        XCTAssertNil(EAN13("12345678901234"))
    }

    func testEAN8() {
        XCTAssertNotNil(EAN8("76543210"))
        XCTAssertNil(EAN8("76543211"))
        XCTAssertNil(EAN8("76543212"))
        XCTAssertNil(EAN8("76543213"))
        XCTAssertNil(EAN8("76543214"))
        XCTAssertNil(EAN8("76543215"))
        XCTAssertNil(EAN8("76543216"))
        XCTAssertNil(EAN8("76543217"))
        XCTAssertNil(EAN8("76543218"))
        XCTAssertNil(EAN8("76543219"))

        XCTAssertNil(EAN8("87654320"))
        XCTAssertNil(EAN8("87654321"))
        XCTAssertNil(EAN8("87654322"))
        XCTAssertNil(EAN8("87654323"))
        XCTAssertNil(EAN8("87654324"))
        XCTAssertNotNil(EAN8("87654325"))
        XCTAssertNil(EAN8("87654326"))
        XCTAssertNil(EAN8("87654327"))
        XCTAssertNil(EAN8("87654328"))
        XCTAssertNil(EAN8("87654329"))
        XCTAssertEqual(EAN8.checkDigit(for: "87654325"), 5)
        XCTAssertEqual(EAN8.checkDigit(for: "8765432"), 5)

        // test failures
        XCTAssertNil(EAN8(""))
        XCTAssertNil(EAN8("123456"))
        XCTAssertNil(EAN8("123456789"))
        XCTAssertNil(EAN8("1234567A"))
    }

    func testEAN() {
        var ean8 = EAN.parse("76543210")
        XCTAssert(ean8 != nil)
        XCTAssertEqual(ean8?.code, "76543210")
        XCTAssertEqual(ean8?.encoding, .ean8)

        ean8 = EAN.parse("7654321")
        XCTAssert(ean8 != nil)
        XCTAssertEqual(ean8?.code, "76543210")
        XCTAssertEqual(ean8?.encoding, .ean8)

        var ean13 = EAN.parse("2001234000000")
        XCTAssert(ean13 != nil)
        XCTAssertEqual(ean13?.code, "2001234000000")
        XCTAssertEqual(ean13?.encoding, .ean13)

        ean13 = EAN.parse("200123400000")
        XCTAssert(ean13 != nil)
        XCTAssertEqual(ean13?.code, "2001234000000")
        XCTAssertEqual(ean13?.encoding, .ean13)
    }

    func testCart() {
        let dbConfig = ProductDBConfiguration()
        let mockProvider = MockProductDB(dbConfig)

        var config = CartConfig()
        config.productProvider = mockProvider
        
        let cart = ShoppingCart(config)
        cart.removeAll()

        cart.add(mockProvider.prod1, quantity: 1)
        XCTAssertEqual(cart.count, 1)
        XCTAssertEqual(cart.numberOfItems(), 1)

        cart.add(mockProvider.prod2, quantity: 1)
        XCTAssertEqual(cart.count, 2)
        XCTAssertEqual(cart.numberOfItems(), 2)

        cart.add(mockProvider.prod1, quantity: 2)
        XCTAssertEqual(cart.count, 2)
        XCTAssertEqual(cart.numberOfItems(), 4)

        XCTAssertEqual(cart.at(0).sku, "1")

        cart.moveEntry(from: 0, to: 1)
        XCTAssertEqual(cart.at(0).sku, "2")
        XCTAssertEqual(cart.at(1).sku, "1")
    }
}
