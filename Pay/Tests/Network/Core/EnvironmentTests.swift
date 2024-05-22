//
//  EnvironmentTests.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import XCTest
@testable import SnabblePayNetwork

final class EnvironmentTests: XCTestCase {
    func testDevelopmentBaseURL() throws {
        let environment: Environment = .development
        XCTAssertEqual(environment.baseURL, "https://payment.snabble-testing.io")
    }

    func testStagingBaseURL() throws {
        let environment: Environment = .staging
        XCTAssertEqual(environment.baseURL, "https://payment.snabble-staging.io")
    }

    func testProductionBaseURL() throws {
        let environment: Environment = .production
        XCTAssertEqual(environment.baseURL, "https://payment.snabble.io")
    }
}
