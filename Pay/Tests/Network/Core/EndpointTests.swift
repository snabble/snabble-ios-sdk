//
//  EndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import XCTest
@testable import SnabblePayNetwork

struct Mock: Decodable {
    let name: String
}

final class EndpointTests: XCTestCase {
    func testDefaultInit() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil))
        XCTAssertEqual(endpoint.method, .get(nil))
        XCTAssertEqual(endpoint.path, "/apps/mock")
        XCTAssertEqual(endpoint.environment, .production)
        XCTAssertEqual(endpoint.headerFields, ["Content-Type": "application/json"])
        XCTAssertNil(endpoint.token)
    }

    func testEnvironmentParameter() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil), environment: .staging)
        XCTAssertEqual(endpoint.environment, .staging)

        endpoint = .init(path: "/apps/mock", method: .get(nil), environment: .development)
        XCTAssertEqual(endpoint.environment, .development)

        endpoint = .init(path: "/apps/mock", method: .get(nil), environment: .production)
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testPathParameter() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil))
        XCTAssertEqual(endpoint.path, "/apps/mock")

        endpoint = .init(path: "/foobar/mock2", method: .get(nil))
        XCTAssertEqual(endpoint.path, "/foobar/mock2")
    }

    func testMethodParameter() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil))
        XCTAssertEqual(endpoint.method, .get(nil))

        endpoint = .init(path: "/foobar/mock2", method: .get([.init(name: "foobar", value: "1")]))
        XCTAssertEqual(endpoint.method, .get([.init(name: "foobar", value: "1")]))

        endpoint = .init(path: "/foobar/mock2", method: .head)
        XCTAssertEqual(endpoint.method, .head)
    }

    func testToken() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil))
        XCTAssertNil(endpoint.token)
        XCTAssertNil(try! endpoint.urlRequest().allHTTPHeaderFields?["Authentication"])
        
        endpoint.token = .init(value: "accessToken", expiresAt: .distantFuture, scope: .all, type: .bearer)
        XCTAssertNotNil(endpoint.token)
        XCTAssertEqual(try! endpoint.urlRequest().allHTTPHeaderFields?["Authorization"], "Bearer accessToken")
    }

    func testGETURLRequestWithQueryItems() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get([
            .init(name: "foobar", value: "1"),
            .init(name: "barfoo", value: "100")
        ]))
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://payment.snabble.io/apps/mock?barfoo=100&foobar=1")
        XCTAssertEqual(urlRequest.httpBody, nil)
    }

    func testGETURLRequestWithQueryItemsOverwriteHeaderfields() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get([
            .init(name: "foobar", value: "1"),
            .init(name: "barfoo", value: "100")
        ]))
        endpoint.headerFields = ["Content-Type": "application/text"]
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/text"])
        XCTAssertEqual(urlRequest.url, "https://payment.snabble.io/apps/mock?barfoo=100&foobar=1")
        XCTAssertEqual(urlRequest.httpBody, nil)
    }

    func testPOSTURLRequest() throws {
        let jsonString = """
        [
            {
                "name": "Taylor Swift",
                "age": 26
            },
            {
                "name": "Justin Bieber",
                "age": 25
            }
        ]
        """
        let jsonData = Data(jsonString.utf8)
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .post(jsonData))
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://payment.snabble.io/apps/mock")
        XCTAssertEqual(urlRequest.httpBody, jsonData)
    }

    func testPUTURLRequest() throws {
        let jsonString = """
        [
            {
                "name": "Taylor Swift",
                "age": 26
            },
            {
                "name": "Justin Bieber",
                "age": 25
            }
        ]
        """
        let jsonData = Data(jsonString.utf8)
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .put(jsonData))
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "PUT")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://payment.snabble.io/apps/mock")
        XCTAssertEqual(urlRequest.httpBody, jsonData)
    }

    func testPATCHURLRequest() throws {
        let jsonString = """
        [
            {
                "name": "Taylor Swift",
                "age": 26
            },
            {
                "name": "Justin Bieber",
                "age": 25
            }
        ]
        """
        let jsonData = Data(jsonString.utf8)
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .patch(jsonData))
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "PATCH")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://payment.snabble.io/apps/mock")
        XCTAssertEqual(urlRequest.httpBody, jsonData)
    }

    func testDELETEURLRequest() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .delete)
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "DELETE")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://payment.snabble.io/apps/mock")
        XCTAssertEqual(urlRequest.httpBody, nil)
    }

    func testHEADURLRequest() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .head)
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "HEAD")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://payment.snabble.io/apps/mock")
        XCTAssertEqual(urlRequest.httpBody, nil)
    }
}
