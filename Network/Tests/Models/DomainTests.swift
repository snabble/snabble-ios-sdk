//
//  DomainTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class DomainTests: XCTestCase {
    func testDevelopmentBaseURL() throws {
        let domain: Domain = .testing
        XCTAssertEqual(domain.baseURL, "https://api.snabble-testing.io")
        XCTAssertEqual(domain.headerFields, [
            "Content-Type": "application/json"
        ])
    }

    func testStagingBaseURL() throws {
        let domain: Domain = .staging
        XCTAssertEqual(domain.baseURL, "https://api.snabble-staging.io")
        XCTAssertEqual(domain.headerFields, [
            "Content-Type": "application/json"
        ])
    }

    func testProductionBaseURL() throws {
        let domain: Domain = .production
        XCTAssertEqual(domain.baseURL, "https://api.snabble.io")
        XCTAssertEqual(domain.headerFields, [
            "Content-Type": "application/json"
        ])
    }
}
