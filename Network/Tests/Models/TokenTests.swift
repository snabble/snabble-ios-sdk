//
//  TokenTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class TokenTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsValid() throws {
        let token1 = Token(id: "1", value: "1", issuedAt: .now, expiresAt: .distantFuture)
        XCTAssertTrue(token1.isValid())

        let token2 = Token(id: "1", value: "1", issuedAt: .distantPast, expiresAt: .now - 1)
        XCTAssertFalse(token2.isValid())
    }
}
