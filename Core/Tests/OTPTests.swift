//
//  OTPTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest

import SwiftOTP

class OTPTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOTP() {

        func generatePassword(at time: TimeInterval) -> String {
            let secretString = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZA===="
            let secretData = base32DecodeToData(secretString)
            XCTAssertNotNil(secretData)

            let totp = TOTP(secret: secretData!, digits: 8, timeInterval: 30, algorithm: .sha256)
            XCTAssertNotNil(totp)

            let time = Date(timeIntervalSince1970: time)
            return totp?.generate(time: time) ?? ""
        }

        XCTAssertEqual(generatePassword(at: 59), "46119246")
        XCTAssertEqual(generatePassword(at: 1111111109), "68084774")
        XCTAssertEqual(generatePassword(at: 1111111111), "67062674")
        XCTAssertEqual(generatePassword(at: 1234567890), "91819424")
        XCTAssertEqual(generatePassword(at: 2000000000), "90698825")
        XCTAssertEqual(generatePassword(at: 20000000000), "77737706")
    }
}
