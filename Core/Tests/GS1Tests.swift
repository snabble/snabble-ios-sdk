//
//  GS1Tests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleCore

class GS1Tests: XCTestCase {

    let gs = GS1Code.gs

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func check(_ code: GS1Code, data: [String: String], skipped: [String] = [],
               _ file: StaticString = #file, _ line: UInt = #line) {
        XCTAssertLessThanOrEqual(code.identifiers.count, data.count, file: file, line: line)

        for (ai, value) in data {
            if let identifier = code.identifiers.first(where: { $0.definition.prefix == ai }) {
                XCTAssertEqual(identifier.values[0], value, file: file, line: line)
            } else {
                XCTFail("identifier \(ai) not found", file: file, line: line)
            }
        }

        for skip in skipped {
            if !code.skipped.contains(skip) {
                XCTFail("expected skip \(skip) not found in \(code.skipped)", file: file, line: line)
            }
        }
    }

    func testInvalidCodes() {
        let code1 = GS1Code("")
        XCTAssertEqual(code1.identifiers.count, 0)
        XCTAssertEqual(code1.skipped.count, 0)

        let code2 = GS1Code("\(gs)\(gs)")
        XCTAssertEqual(code2.identifiers.count, 0)
        XCTAssertEqual(code2.skipped, [""])

        let code3 = GS1Code("asdfghjklöä")
        XCTAssertEqual(code3.identifiers.count, 0)
        XCTAssertEqual(code3.skipped.count, 1)

        let code4 = GS1Code("   0100000000000000    ")
        XCTAssertEqual(code4.identifiers.count, 0)
        XCTAssertEqual(code4.skipped.count, 1)

        // invalid lot number
        check(GS1Code("10invälid"), data: [ "10": "inv" ], skipped: [ "älid" ])

        // invalid gtin
        check(GS1Code("010000000000000"), data: [:], skipped: ["010000000000000"])

        // another invalid gtin
        check(GS1Code("01ABCDEFGHIJKLMN"), data: [:], skipped: ["01ABCDEFGHIJKLMN"])

        // empty gtin is also invalid
        check(GS1Code("01"), data: [:], skipped: ["01"])
    }

    func testCodes() {
        // gtin, net weight, empty lot
        check(GS1Code("0102658960000004310300464610"),
              data: [ "01": "02658960000004", "3103": "004646", "10": "" ],
              skipped: [])

        // gtin, net weight, empty lot with gratuituous separators
        check(GS1Code("\(gs)0102658960000004\(gs)3103004646\(gs)10\(gs)"),
              data: [ "01": "02658960000004", "3103": "004646", "10": "" ],
              skipped: [])

        // gtin, net weight, lot with more gratuituous separators
        check(GS1Code("01026589600000043103004646\(gs)\(gs)10test\(gs)\(gs)\(gs)\(gs)"),
              data: [ "01": "02658960000004", "3103": "004646", "10": "test" ],
              skipped: [])

        // gtin, net weight, lot, dangerous goods flag plus two invalid AIs (3109 and 4321)
        check(GS1Code("0102658960000004\(gs)3103004646\(gs)10HALLO\(gs)3109kkkkkk43217\(gs)43210"),
              data: [ "01": "02658960000004", "3103": "004646", "10": "HALLO", "4321": "0" ],
              skipped: [ "3109kkkkkk", "43217" ])

        // valid lot number
        check(GS1Code("10valid"), data: [ "10": "valid"])

        // test with QR code prefix
        check(GS1Code("]Q30100000000000000\(gs)10FOO"), data: [ "01": "00000000000000", "10": "FOO" ])
    }

    func testSingle() {
        check(GS1Code("010000000000000"), data: [:], skipped: ["010000000000000"])
        check(GS1Code("010000000000000_\(gs)01123"), data: [:], skipped: ["010000000000000_", "01123"])
    }

    func testMultivalue() {
        // amount payable, currency=111, value=0123456
        let code1 = GS1Code("39101110123456")
        XCTAssertEqual(code1.identifiers[0].values.count, 2)
        XCTAssertEqual(code1.identifiers[0].values[0], "111")
        XCTAssertEqual(code1.identifiers[0].values[1], "0123456")

        // amount payable, invalid data
        let code2 = GS1Code("3910aaabbbb")
        XCTAssertEqual(code2.identifiers.count, 0)
        XCTAssertEqual(code2.skipped.count, 1)
        XCTAssertEqual(code2.skipped[0], "3910aaabbbb")
    }

    func testDecimal() {
        // net weight in kg, no decimal digits
        let code1 = GS1Code("3100000042")
        XCTAssertEqual(code1.identifiers[0].values.count, 1)
        XCTAssertEqual(code1.identifiers[0].values[0], "000042")
        XCTAssertEqual(code1.identifiers[0].decimal, Decimal(integerLiteral: 42))

        // net weight in kg, 3 decimal digits
        let code2 = GS1Code("3103001042")
        XCTAssertEqual(code2.identifiers[0].values.count, 1)
        XCTAssertEqual(code2.identifiers[0].values[0], "001042")
        XCTAssertEqual(code2.identifiers[0].decimal, Decimal(floatLiteral: 1.042))
    }

    func testWeight() {
        // net weight in kg, no decimal digits: 1kg
        let code1 = GS1Code("3100000001")
        let weight1 = code1.weight(in: .kilogram)
        XCTAssertEqual(weight1, Decimal(integerLiteral: 1))

        // net weight in kg, no decimal digits: 1kg
        let code2 = GS1Code("3100000001")
        let weight2 = code2.weight(in: .gram)
        XCTAssertEqual(weight2, Decimal(integerLiteral: 1000))

        // net weight in kg, 3 decimal digits: 1.02kg
        let code3 = GS1Code("3103001020")
        let weight3 = code3.weight(in: .gram)
        XCTAssertEqual(weight3, Decimal(integerLiteral: 1020))

        // net weight in kg, 2 decimal digits: 1.23kg
        let code4 = GS1Code("3102000123")
        let weight4 = code4.weight(in: .decagram)
        XCTAssertEqual(weight4, Decimal(integerLiteral: 123))

        // net weight in kg, 2 decimal digits: 1.24kg
        let code5 = GS1Code("3102000124")
        let weight5 = code5.weight(in: .hectogram)
        XCTAssertEqual(weight5, Decimal(floatLiteral: 12.4))

        XCTAssertEqual(GS1Code("3100000001").weight, 1000)
        XCTAssertEqual(GS1Code("3101000011").weight, 1100)
        XCTAssertEqual(GS1Code("3102000124").weight, 1240)
        XCTAssertEqual(GS1Code("3103001001").weight, 1001)

        XCTAssertNil(GS1Code("3102000124").weight(in: .liter))
        XCTAssertNil(GS1Code("3902000124").weight(in: .kilogram))
    }

    func testLength() {
        // net length in m, no decimal digits: 1m
        let code1 = GS1Code("3110000001")
        let length1 = code1.length(in: .meter)
        XCTAssertEqual(length1, Decimal(integerLiteral: 1))

        // net length in m, no decimal digits: 1m
        let code2 = GS1Code("3110000001")
        let length2 = code2.length(in: .millimeter)
        XCTAssertEqual(length2, Decimal(integerLiteral: 1000))

        // net length in m, 3 decimal digits: 1.02m
        let code3 = GS1Code("3113001020")
        let length3 = code3.length(in: .millimeter)
        XCTAssertEqual(length3, Decimal(integerLiteral: 1020))

        // net length in m, 2 decimal digits: 1.23m
        let code4 = GS1Code("3112000123")
        let length4 = code4.length(in: .centimeter)
        XCTAssertEqual(length4, Decimal(integerLiteral: 123))

        // net length in m, 2 decimal digits: 1.24m
        let code5 = GS1Code("3112000124")
        let length5 = code5.length(in: .decimeter)
        XCTAssertEqual(length5, Decimal(floatLiteral: 12.4))

        XCTAssertEqual(GS1Code("3110000001").length, 1000)
        XCTAssertEqual(GS1Code("3111000011").length, 1100)
        XCTAssertEqual(GS1Code("3112000124").length, 1240)
        XCTAssertEqual(GS1Code("3113001001").length, 1001)

        XCTAssertNil(GS1Code("3102000124").length(in: .liter))
        XCTAssertNil(GS1Code("3902000124").length(in: .meter))
    }

    func testLiters() {
        // net volume in l, no decimal digits: 1l
        let code1 = GS1Code("3150000001")
        let liters1 = code1.liters(in: .liter)
        XCTAssertEqual(liters1, Decimal(integerLiteral: 1))

        // net volume in l, no decimal digits: 1l
        let code2 = GS1Code("3150000001")
        let liters2 = code2.liters(in: .milliliter)
        XCTAssertEqual(liters2, Decimal(integerLiteral: 1000))

        // net volume in l, 3 decimal digits: 1.02l
        let code3 = GS1Code("3153001020")
        let liters3 = code3.liters(in: .milliliter)
        XCTAssertEqual(liters3, Decimal(integerLiteral: 1020))

        // net volume in l, 2 decimal digits: 1.23l
        let code4 = GS1Code("3152000123")
        let liters4 = code4.liters(in: .centiliter)
        XCTAssertEqual(liters4, Decimal(integerLiteral: 123))

        // net volume in l, 2 decimal digits: 1.24l
        let code5 = GS1Code("3152000124")
        let liters5 = code5.liters(in: .deciliter)
        XCTAssertEqual(liters5, Decimal(floatLiteral: 12.4))

        XCTAssertEqual(GS1Code("3150000001").liters, 1000)
        XCTAssertEqual(GS1Code("3151000011").liters, 1100)
        XCTAssertEqual(GS1Code("3152000124").liters, 1240)
        XCTAssertEqual(GS1Code("3153001001").liters, 1001)

        XCTAssertNil(GS1Code("3102000124").length(in: .squareCentimeter))
        XCTAssertNil(GS1Code("3902000124").liters(in: .liter))
    }

    func testArea() {
        // net area in m^2, no decimal digits: 1m^2
        let code1 = GS1Code("3140000001")
        let area1 = code1.area(in: .squareMeter)
        XCTAssertEqual(area1, Decimal(integerLiteral: 1))

        // net area in m^2, no decimal digits: 1m^2
        let code2 = GS1Code("3140000001")
        let area2 = code2.area(in: .squareCentimeter)
        XCTAssertEqual(area2, Decimal(integerLiteral: 10000))

        // net area in m^2, 3 decimal digits: 1.02m^2
        let code3 = GS1Code("3143001020")
        let area3 = code3.area(in: .squareCentimeter)
        XCTAssertEqual(area3, Decimal(integerLiteral: 10200))

        // net area in m^2, 3 decimal digits: 1.23m^2
        let code4 = GS1Code("3143001230")
        let area4 = code4.area(in: .squareCentimeter)
        XCTAssertEqual(area4, Decimal(integerLiteral: 12300))

        // net area in m^2, 2 decimal digits: 1.24m^2
        let code5 = GS1Code("3142000124")
        let area5 = code5.area(in: .squareDecimeter)
        XCTAssertEqual(area5, Decimal(floatLiteral: 124))

        XCTAssertEqual(GS1Code("3140000001").area, 10000)
        XCTAssertEqual(GS1Code("3141000011").area, 11000)
        XCTAssertEqual(GS1Code("3142000124").area, 12400)
        XCTAssertEqual(GS1Code("3143001001").area, 10010)

        XCTAssertNil(GS1Code("3102000124").area(in: .liter))
        XCTAssertNil(GS1Code("3902000124").area(in: .squareCentimeter))
    }

    func testVolume() {
        // net volume in m^3, no decimal digits: 1m^3
        let code1 = GS1Code("3160000001")
        let volume1 = code1.volume(in: .cubicMeter)
        XCTAssertEqual(volume1, Decimal(integerLiteral: 1))

        // net volume in m^3, no decimal digits: 1m^3
        let code2 = GS1Code("3160000001")
        let volume2 = code2.volume(in: .cubicCentimeter)
        XCTAssertEqual(volume2, Decimal(integerLiteral: 1_000_000))

        // net volume in m^3, 3 decimal digits: 1.02m^3
        let code3 = GS1Code("3163001020")
        let volume3 = code3.volume(in: .cubicMeter)
        XCTAssertEqual(volume3, Decimal(floatLiteral: 1.020))

        // net length in m^3, 3 decimal digits: 1.23m^3
        let code4 = GS1Code("3163001230")
        let volume4 = code4.volume(in: .cubicMeter)
        XCTAssertEqual(volume4, Decimal(floatLiteral: 1.23))

        // net length in m^3, 2 decimal digits: 1.24m^3
        let code5 = GS1Code("3162000124")
        let volume5 = code5.volume(in: .cubicCentimeter)
        XCTAssertEqual(volume5, Decimal(integerLiteral: 1240000))

        XCTAssertEqual(GS1Code("3160000001").volume, 1000000)
        XCTAssertEqual(GS1Code("3161000011").volume, 1100000)
        XCTAssertEqual(GS1Code("3162000124").volume, 1240000)
        XCTAssertEqual(GS1Code("3163001001").volume, 1001000)

        XCTAssertNil(GS1Code("3102000124").volume(in: .liter))
        XCTAssertNil(GS1Code("3902000124").volume(in: .cubicCentimeter))
    }

    func testAmount() {
        let code1 = GS1Code("3042")
        XCTAssertEqual(code1.amount, 42)

        let code2 = GS1Code("30xx")
        XCTAssertEqual(code2.amount, nil)
    }

    func testRawPrice() {
        // amount payable, no decimal digits: 12
        let code1 = GS1Code("392012")
        let price1 = code1.price
        XCTAssertEqual(price1?.price, Decimal(integerLiteral: 12))
        XCTAssertEqual(price1?.currency, nil)

        // amount payable, 2 decimal digits: 12.34
        let code2 = GS1Code("39221234")
        let price2 = code2.price
        XCTAssertEqual(price2?.price, Decimal(floatLiteral: 12.34))
        XCTAssertEqual(price2?.currency, nil)

        // amount payable in EUR (978), no decimal digits: 13
        let code3 = GS1Code("393097813")
        let price3 = code3.price
        XCTAssertEqual(price3?.price, Decimal(integerLiteral: 13))
        XCTAssertEqual(price3?.currency, "978")

        // amount payable in EUR (978), 2 decimal digits: 13.45
        let code4 = GS1Code("39329781345")
        let price4 = code4.price
        XCTAssertEqual(price4?.price, Decimal(floatLiteral: 13.45))
        XCTAssertEqual(price4?.currency, "978")
    }

    // test price conversions for cart, i.e. convert decimals
    // from the AI into whatever we need in snabble
    func testPriceForCart2Decimals() {
        let decimalDigits = 2

        // amount payable, no decimal digits: 12 -> 1200
        let code1 = GS1Code("392012")
        let price1 = code1.price(decimalDigits, .down)
        XCTAssertEqual(price1, 1200)

        // amount payable, 2 decimal digits: 12.34
        let code2 = GS1Code("39221234")
        let price2 = code2.price(decimalDigits, .down)
        XCTAssertEqual(price2, 1234)

        // amount payable, 1 decimal digit: 12.4
        let code3 = GS1Code("3921124")
        let price3 = code3.price(decimalDigits, .down)
        XCTAssertEqual(price3, 1240)

        // amount payable, 3 decimal digits: 12.456
        let code4 = GS1Code("392312456")
        let price4 = code4.price(decimalDigits, .down)
        XCTAssertEqual(price4, 1245)
    }

    func testPriceForCart0Decimals() {
        let decimalDigits = 0 // e.g. Forint

        // amount payable, no decimal digits: 12 -> 12ft
        let code1 = GS1Code("392012")
        let price1 = code1.price(decimalDigits, .down)
        XCTAssertEqual(price1, 12)

        // amount payable, 2 decimal digits: 12 ft
        let code2 = GS1Code("39221200")
        let price2 = code2.price(decimalDigits, .down)
        XCTAssertEqual(price2, 12)
    }

    func testEmbeddedData() {
        let code = GS1Code(
            "3113000123" + // len
            "3103000124" + // weight
            "3153000125" + // liters
            "3163000126" + // volume
            "3143000127" + // area
            "39221234\(gs)" +   // price
            "3042" // amount
        )

        let len = code.getEmbeddedData(for: .meter, 2, .down)
        XCTAssertEqual(len.0, 123)
        XCTAssertEqual(len.1, .millimeter)

        let kg = code.getEmbeddedData(for: .kilogram, 2, .down)
        XCTAssertEqual(kg.0, 124)
        XCTAssertEqual(kg.1, .gram)

        let l = code.getEmbeddedData(for: .liter, 2, .down)
        XCTAssertEqual(l.0, 125)
        XCTAssertEqual(l.1, .milliliter)

        let m3 = code.getEmbeddedData(for: .cubicMeter, 2, .down)
        XCTAssertEqual(m3.0, 126000)
        XCTAssertEqual(m3.1, .cubicCentimeter)

        let m2 = code.getEmbeddedData(for: .squareMeter, 2, .down)
        XCTAssertEqual(m2.0, 1270)
        XCTAssertEqual(m2.1, .squareCentimeter)

        let price = code.getEmbeddedData(for: .price, 2, .down)
        XCTAssertEqual(price.0, 1234)
        XCTAssertEqual(price.1, .price)

        let piece = code.getEmbeddedData(for: .piece, 2, .down)
        XCTAssertEqual(piece.0, 42)
        XCTAssertEqual(piece.1, .piece)
    }

    func testTeeGschwendner() {
        // code from TG's "Verkaufsverpackungsbarcodegenerator"
        // missing a (GS) after AI 30, and has invalid chars in AI 10
        let code = GS1Code("010000000001234530000000011520101510              CHARGE")
        XCTAssertEqual(code.gtin, "00000000012345")
        XCTAssertEqual(code.amount, 1) // works because the regex is greedy
        XCTAssertEqual(code.identifiers[2].definition.prefix, "15")
        XCTAssertEqual(code.identifiers[2].values[0], "201015")
        XCTAssertEqual(code.skipped, ["              CHARGE"])

        // standard conforming version of the same code
        let code2 = GS1Code("0100000000012345301\u{1D}1520101510CHARGE")
        XCTAssertEqual(code2.gtin, "00000000012345")
        XCTAssertEqual(code2.amount, 1)
        XCTAssertEqual(code2.identifiers[2].definition.prefix, "15")
        XCTAssertEqual(code2.identifiers[2].values[0], "201015")
        XCTAssertEqual(code2.identifiers[3].definition.prefix, "10")
        XCTAssertEqual(code2.identifiers[3].values[0], "CHARGE")
        XCTAssertEqual(code2.skipped, [])
    }
}
