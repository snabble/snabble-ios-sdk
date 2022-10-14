//
//  EANTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleSDK

class EANTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func checkInternal(_ code: String, _ check: Int) {
        let ean = EAN.parse(code) as? EAN13
        XCTAssertNotNil(ean)
        if let ean = ean {
            let internalCheck = ean.internalChecksum5()
            XCTAssertEqual(internalCheck, check, "\(ean.code)")
        }
    }

    // test checksum calculation for EANs with embedded 5-digit price/weight
    func testWeighEAN5() {
        checkInternal("281027614685", 6)
        checkInternal("2810275005024", 5)
        checkInternal("2746724008288", 4)
        checkInternal("2850090007827", 0)
        checkInternal("2957776004085", 6)
        checkInternal("2957822002843", 2)
        checkInternal("2810606013360", 6)
        checkInternal("2810270002387", 0)
        checkInternal("2810478001908", 8)
        checkInternal("2893482001744", 2)
        checkInternal("2957796002801", 6)
        checkInternal("2893035003607", 5)
        checkInternal("2810115003609", 5)
        checkInternal("2810444001505", 4)
        checkInternal("2893525001724", 5)
        checkInternal("2957783000742", 3)
        checkInternal("2958300015089", 0)
        checkInternal("2810307003349", 7)
        checkInternal("2810029003221", 9)
        checkInternal("2810030004729", 0)
        checkInternal("2956755020146", 5)
        checkInternal("2957736007385", 6)
        checkInternal("2957679012040", 9)
        checkInternal("2810063024800", 3)

        checkInternal("2850256002345", 6)
        checkInternal("2490718001495", 8)
        checkInternal("2599499000052", 9)

        checkInternal("2407002000454", 2) // edeka "äpfel red chief"
        checkInternal("2407002001420", 2) // edeka "haselnüsse lose"

        checkInternal("242323000154", 0) // demo braeburn, gewicht 154g
        checkInternal("252323200006", 2) // demo braeburn, 6 stück
        checkInternal("262323700249", 7) // demo braeburn, preis 2.49€
        checkInternal("252323000000", 0) // demo braeburn, 0 stück
    }

    // test checksum calculation for EANs with embedded 4-digit price/weight
    func testWeighEAN4() {
        let ean = EAN.parse("2001235928754")
        XCTAssertNotNil(ean)
        if let ean = ean as? EAN13 {
            XCTAssertEqual(ean.internalChecksum4(), 9)
        }
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

    func testEAN14() {
        // regular EAN-14
        XCTAssertNotNil(EAN14("18594001694690"))
        XCTAssertNotNil(EAN14("28000017120605"))
        XCTAssertNotNil(EAN14("40700719670720"))

        // test for wrong check digit
        XCTAssertNil(EAN14("18594001694691"))
        XCTAssertNil(EAN14("28000017120606"))
        XCTAssertNil(EAN14("40700719670721"))

        // EAN-14 from a Code-128 barcode ("01" as prefix)
        XCTAssertNotNil(EAN14("18594001694690"))
        XCTAssertNotNil(EAN14("28000017120605"))
        XCTAssertNotNil(EAN14("40700719670720"))
    }

    func testEAN() {
        var ean8 = EAN.parse("76543210")
        XCTAssert(ean8 != nil)
        XCTAssertEqual(ean8?.code, "76543210")
        XCTAssertEqual(ean8?.encoding, .ean8)
        XCTAssertEqual(ean8?.checkDigit, 0)

        ean8 = EAN.parse("7654321")
        XCTAssert(ean8 != nil)
        XCTAssertEqual(ean8?.code, "76543210")
        XCTAssertEqual(ean8?.encoding, .ean8)
        XCTAssertEqual(ean8?.checkDigit, 0)

        var ean13 = EAN.parse("2001234000000")
        XCTAssert(ean13 != nil)
        XCTAssertEqual(ean13?.code, "2001234000000")
        XCTAssertEqual(ean13?.encoding, .ean13)
        XCTAssertEqual(ean13?.checkDigit, 0)

        ean13 = EAN.parse("200123400000")
        XCTAssert(ean13 != nil)
        XCTAssertEqual(ean13?.code, "2001234000000")
        XCTAssertEqual(ean13?.encoding, .ean13)
        XCTAssertEqual(ean13?.checkDigit, 0)

        XCTAssertNil(EAN.checkDigit(for: "40297640018"))
        XCTAssertNil(EAN.checkDigit(for: "foo"))

        let ean14 = EAN.parse("18594001694690")
        XCTAssert(ean14 != nil)
        XCTAssertEqual(ean14?.code, "18594001694690")
        XCTAssertEqual(ean14?.encoding, .ean14)
        XCTAssertEqual(ean14?.checkDigit, 0)

        XCTAssertEqual(EAN.checkDigit(for: "87654325"), 5)
        XCTAssertEqual(EAN.checkDigit(for: "8765432"), 5)
        XCTAssertEqual(EAN.checkDigit(for: "4029764001807"), 7)
        XCTAssertEqual(EAN.checkDigit(for: "402976400180"), 7)
        XCTAssertEqual(EAN.checkDigit(for: "18594001694690"), 0)
    }

    func testEanEncoding() {
        let bits13 = EAN.encode("4029764001807")
        XCTAssertNotNil(bits13)
        XCTAssertEqual(bits13!.count, 113)
        XCTAssertEqual(bits13!, [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0])

        let bits8 = EAN.encode("76543210")
        XCTAssertNotNil(bits8)
        XCTAssertEqual(bits8!.count, 85)
        XCTAssertEqual(bits8!, [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0])

        XCTAssertNil(EAN.encode("4029764001808"))
        XCTAssertNil(EAN.encode("402976400180a"))
        XCTAssertNil(EAN.encode("76543211"))
        XCTAssertNil(EAN.encode("7654321a"))
        XCTAssertNil(EAN.encode("123"))
        XCTAssertNil(EAN.encode("foo"))
    }

}
