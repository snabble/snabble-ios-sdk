//
//  AppUserEndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class AppUserEndpointTests: XCTestCase {

    var configuration: Configuration = .init(appId: "1", appSecret: "ABCDEFGHIJKLMNOP", domain: .production)

    func testPostWithoutProject() throws {
        let endpoint = Endpoints.AppUser.post(appId: configuration.appId, appSecret: configuration.appSecret)
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/apps/1/users")
        XCTAssertNotNil(endpoint.headerFields["Authorization"])
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/1/users")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNil(urlRequest.httpBody)
    }

    func testPostWithProject() throws {
        let endpoint = Endpoints.AppUser.post(appId: configuration.appId, appSecret: configuration.appSecret)
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/apps/1/users")
        XCTAssertNotNil(endpoint.headerFields["Authorization"])
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/1/users")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertNil(urlRequest.httpBody)
    }
}
