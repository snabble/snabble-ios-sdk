//
//  HTTPMethodTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class HTTPMethodTests: XCTestCase {
    func testGETValue() throws {
        let method: HTTPMethod = .get(nil)
        XCTAssertEqual(method.value, "GET")
    }

    func testPATCHValue() throws {
        let method: HTTPMethod = .patch(nil)
        XCTAssertEqual(method.value, "PATCH")
    }

    func testPUTValue() throws {
        let method: HTTPMethod = .put(nil)
        XCTAssertEqual(method.value, "PUT")
    }

    func testPOSTValue() throws {
        let method: HTTPMethod = .post(nil)
        XCTAssertEqual(method.value, "POST")
    }

    func testDELETEValue() throws {
        let method: HTTPMethod = .delete
        XCTAssertEqual(method.value, "DELETE")
    }

    func testHEADValue() throws {
        let method: HTTPMethod = .head
        XCTAssertEqual(method.value, "HEAD")
    }
}
