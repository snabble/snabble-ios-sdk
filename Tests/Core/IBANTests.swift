//
//  IBANTests.swift
//  SnabbleAppTests
//
//  Created by Gereon Steffens on 27.08.19.
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleSDK

class IBANTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIbanFormatting() {
        XCTAssertEqual(IBAN.displayName("DE75512108001245126199"), "DE75 •••• •••• •••• •••• 99")
        XCTAssertEqual(IBAN.displayName("NL02ABNA0123456789"), "NL02 •••• •••• •••• 89")
        XCTAssertEqual(IBAN.displayName("XX00__xx__11"), "XX00 •••••• 11")
    }

}
