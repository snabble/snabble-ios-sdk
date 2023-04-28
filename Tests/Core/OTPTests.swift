//
//  OTPTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest

import OneTimePassword
import Base32

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
            let secretData = MF_Base32Codec.data(fromBase32String: secretString)
            XCTAssertNotNil(secretData)

            let generator = try? Generator(factor: .timer(period: 30), secret: secretData!, algorithm: .sha256, digits: 8)
            XCTAssertNotNil(generator)

            let token = Token(name: "", issuer: "", generator: generator!)
            let time = Date(timeIntervalSince1970: time)
            do {
                return try token.generator.password(at: time)
            } catch {
                XCTFail("generator failed: \(error)")
                return ""
            }
        }

        XCTAssertEqual(generatePassword(at: 59), "46119246")
        XCTAssertEqual(generatePassword(at: 1111111109), "68084774")
        XCTAssertEqual(generatePassword(at: 1111111111), "67062674")
        XCTAssertEqual(generatePassword(at: 1234567890), "91819424")
        XCTAssertEqual(generatePassword(at: 2000000000), "90698825")
        XCTAssertEqual(generatePassword(at: 20000000000), "77737706")
    }
}
