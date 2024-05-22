//
//  TokenEndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class TokenEndpointTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var configuration: Configuration = .init(appId: "1", appSecret: "ABCDEFGHIJKLMNOP", domain: .production)
    var appUser: AppUser = .init(id: "555", secret: "123-456-789")

    func testGet() throws {
        let endpoint = Endpoints.Token.get(appId: configuration.appId, appSecret: configuration.appSecret, appUser: appUser, projectId: "2")
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "GET")
        XCTAssertEqual(endpoint.path, "/tokens")
        XCTAssertNotNil(endpoint.headerFields["Authorization"])
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/tokens?project=2&role=retailerApp")
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertNil(urlRequest.httpBody)
    }
}
