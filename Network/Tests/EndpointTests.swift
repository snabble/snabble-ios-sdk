//
//  EndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

struct Mock: Decodable {
    let name: String
}

final class EndpointTests: XCTestCase {

    let configuration: Configuration = .init(appId: "1", appSecret: "2", domain: .production)
    func testDefaultInit() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil)) { _ in
            return Mock(name: "foobar")
        }
        XCTAssertEqual(endpoint.method, .get(nil))
        XCTAssertEqual(endpoint.path, "/apps/mock")
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.headerFields, [:])
        XCTAssertNil(endpoint.token)
    }

    func testEnvironmentParameter() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil)) { _ in
            Mock(name: "foobar")
        }
        XCTAssertEqual(endpoint.domain, .production)
    }

    func testPathParameter() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil)) { _ in
            Mock(name: "foobar")
        }
        XCTAssertEqual(endpoint.path, "/apps/mock")

        endpoint = .init(path: "/foobar/mock2", method: .get(nil)) { _ in
            Mock(name: "foobar")
        }
        XCTAssertEqual(endpoint.path, "/foobar/mock2")
    }

    func testMethodParameter() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil)) { _ in
            Mock(name: "foobar")
        }
        XCTAssertEqual(endpoint.method, .get(nil))

        endpoint = .init(path: "/apps/mock", method: .get([.init(name: "foobar", value: "1")])) { _ in
            Mock(name: "foobar")
        }
        XCTAssertEqual(endpoint.method, .get([.init(name: "foobar", value: "1")]))

        endpoint = .init(path: "/apps/mock", method: .head) { _ in
            Mock(name: "foobar")
        }
        XCTAssertEqual(endpoint.method, .head)
    }

    func testToken() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get(nil)) { _ in
            Mock(name: "foobar")
        }
        XCTAssertNil(endpoint.token)
        XCTAssertNil(try! endpoint.urlRequest().allHTTPHeaderFields?["Authentication"])

        endpoint.token = .init(id: "1", value: "accessToken", issuedAt: Date(), expiresAt: .distantFuture)
        XCTAssertNotNil(endpoint.token)
        XCTAssertEqual(try! endpoint.urlRequest().allHTTPHeaderFields?["Authorization"], "Bearer accessToken")
    }

    func testGETURLRequestWithQueryItems() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get([
            .init(name: "foobar", value: "1"),
            .init(name: "barfoo", value: "100")
        ])) { _ in
            Mock(name: "foobar")
        }
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://api.snabble.io/apps/mock?barfoo=100&foobar=1")
        XCTAssertEqual(urlRequest.httpBody, nil)
    }

    func testGETURLRequestWithQueryItemsOverwriteHeaderfields() throws {
        var endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .get([
            .init(name: "foobar", value: "1"),
            .init(name: "barfoo", value: "100")
        ])) { _ in
            Mock(name: "foobar")
        }
        endpoint.headerFields = ["Content-Type": "application/text"]
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/text"])
        XCTAssertEqual(urlRequest.url, "https://api.snabble.io/apps/mock?barfoo=100&foobar=1")
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
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .post(jsonData)) { _ in
            Mock(name: "foobar")
        }
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://api.snabble.io/apps/mock")
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
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .put(jsonData)) { _ in
            Mock(name: "foobar")
        }
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "PUT")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://api.snabble.io/apps/mock")
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
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .patch(jsonData)) { _ in
            Mock(name: "foobar")
        }
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "PATCH")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://api.snabble.io/apps/mock")
        XCTAssertEqual(urlRequest.httpBody, jsonData)
    }

    func testDELETEURLRequest() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .delete) { _ in
            Mock(name: "foobar")
        }
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "DELETE")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://api.snabble.io/apps/mock")
    }

    func testHEADURLRequest() throws {
        let endpoint: Endpoint<Mock> = .init(path: "/apps/mock", method: .head) { _ in
            Mock(name: "foobar")
        }
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.httpMethod, "HEAD")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json"])
        XCTAssertEqual(urlRequest.url, "https://api.snabble.io/apps/mock")
        XCTAssertEqual(urlRequest.httpBody, nil)
    }
}
