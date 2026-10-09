//
//  EnvironmentTests.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import Testing
@testable import SnabblePayNetwork

@Suite
struct EnvironmentTests {
    @Test func testDevelopmentBaseURL() throws {
        let environment: Environment = .development
        #expect(environment.baseURL == "https://payment.snabble-testing.io")
    }

    @Test func testStagingBaseURL() throws {
        let environment: Environment = .staging
        #expect(environment.baseURL == "https://payment.snabble-staging.io")
    }

    @Test func testProductionBaseURL() throws {
        let environment: Environment = .production
        #expect(environment.baseURL == "https://payment.snabble.io")
    }
}
