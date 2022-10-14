//
//  UnitsTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleCore

class UnitsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUnitConversions() {
        XCTAssertEqual(Units.convert(200, from: .centimeter, to: .meter), 2)
        XCTAssertEqual(Units.convert(3, from: .meter, to: .centimeter), 300)

        XCTAssertEqual(Units.convert(200, from: .milliliter, to: .liter), 0.2)
        XCTAssertEqual(Units.convert(300, from: .milliliter, to: .centiliter), 30)
        XCTAssertEqual(Units.convert(400, from: .milliliter, to: .deciliter), 4)
        XCTAssertEqual(Units.convert(50, from: .centiliter, to: .deciliter), 5)
        XCTAssertEqual(Units.convert(60, from: .centiliter, to: .liter), 0.6)
        XCTAssertEqual(Units.convert(70, from: .deciliter, to: .liter), 7)

        XCTAssertEqual(Units.convert(2, from: .squareMeter, to: .squareCentimeter), 20_000)
        XCTAssertEqual(Units.convert(2.5, from: .squareMeter, to: .squareCentimeter), 25_000)

        XCTAssertEqual(Units.convert(3000, from: .kilogram, to: .tonne), 3)
        XCTAssertEqual(Units.convert(3, from: .tonne, to: .kilogram), 3000)

        XCTAssertEqual(Units.convert(2, from: .price, to: .price), 2)

        XCTAssertEqual(Units.convert(42, from: .centimeter, to: .liter), 0)

        XCTAssertEqual(Units.convert(300, from: .gram, to: .hectogram), 3)
        XCTAssertEqual(Units.convert(2, from: .hectogram, to: .gram), 200)
        XCTAssertEqual(Units.convert(300, from: .gram, to: .decagram), 30)
        XCTAssertEqual(Units.convert(400, from: .gram, to: .hectogram), 4)
        XCTAssertEqual(Units.convert(500, from: .decagram, to: .kilogram), 5)
        XCTAssertEqual(Units.convert(60, from: .decagram, to: .hectogram), 6)
        XCTAssertEqual(Units.convert(70, from: .gram, to: .kilogram), Decimal(string: "0.07")!)
    }

    func testUnitFractions() {
        XCTAssertEqual(Units.kilogram.fractionalUnit(10)!, Units.hectogram)
        XCTAssertEqual(Units.kilogram.fractionalUnit(100)!, Units.decagram)
        XCTAssertEqual(Units.kilogram.fractionalUnit(1000)!, Units.gram)
    }

}
