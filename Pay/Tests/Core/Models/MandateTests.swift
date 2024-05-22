//
//  MandateTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-24.
//

import XCTest
@testable import SnabblePay
import TestHelper

final class MandateTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEquatable() throws {
        let mandate1 = Account.Mandate(id: "0", state: .pending, htmlText: nil)
        let mandate2 = Account.Mandate(id: "0", state: .accepted, htmlText: nil)
        let mandate3 = Account.Mandate(id: "1", state: .pending, htmlText: nil)

        XCTAssertEqual(mandate1, mandate2)
        XCTAssertFalse(mandate1 == mandate3)
    }

}
