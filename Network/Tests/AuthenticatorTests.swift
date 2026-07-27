//
//  AuthenticatorTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

// Thread-safe counter for verifying request counts across concurrent network calls.
private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    var count: Int { lock.withLock { _count } }
    func increment() { lock.withLock { _count += 1 } }
}

extension Authenticator: @unchecked Sendable {}

@MainActor
final class AuthenticatorTests: XCTestCase, @unchecked Sendable {

    var authenticator: Authenticator!
    var configuration = Configuration(appId: "123", appSecret: "123-456-789", domain: .testing)

    override func setUpWithError() throws {
        authenticator = .init(urlSession: .mockSession)
        authenticator.delegate = self
    }

    override func tearDownWithError() throws {
        authenticator = nil
    }

    func testValidateToken() async throws {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { request in
            switch request.url {
            case "https://api.snabble-testing.io/apps/123/users":
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, try loadResource(inBundle: .module, filename: "UsersResponse-Without-Token", withExtension: "json"))
            case "https://api.snabble-testing.io/tokens?project=1&role=retailerApp":
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, try loadResource(inBundle: .module, filename: "Token", withExtension: "json"))
            default:
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data())
            }
        }

        let token = try await authenticator.validToken(withConfiguration: configuration)
        XCTAssertNotNil(token)
    }

    /// Verifies that concurrent calls to validToken share a single in-flight task and
    /// therefore fire POST /users exactly once, not once per caller.
    func testConcurrentValidTokenCallsFireOnlyOnePostRequest() async throws {
        let postCounter = RequestCounter()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            switch request.url {
            case "https://api.snabble-testing.io/apps/123/users":
                postCounter.increment()
                return (response, try loadResource(inBundle: .module,
                    filename: "UsersResponse-Without-Token", withExtension: "json"))
            case "https://api.snabble-testing.io/tokens?project=1&role=retailerApp":
                return (response, try loadResource(inBundle: .module,
                    filename: "Token", withExtension: "json"))
            default:
                return (HTTPURLResponse(url: request.url!, statusCode: 500,
                    httpVersion: nil, headerFields: nil)!, Data())
            }
        }

        // All three tasks start before any response arrives; they share the same refreshTask.
        async let t1 = authenticator.validToken(withConfiguration: configuration)
        async let t2 = authenticator.validToken(withConfiguration: configuration)
        async let t3 = authenticator.validToken(withConfiguration: configuration)
        _ = try await (t1, t2, t3)

        XCTAssertEqual(postCounter.count, 1,
            "POST /users must be fired exactly once regardless of concurrent caller count")
    }

    /// Verifies that the token received from the first validToken call is cached and
    /// reused by subsequent calls without triggering new network requests.
    func testTokenIsCachedAfterFirstValidation() async throws {
        let postCounter = RequestCounter()
        let tokenCounter = RequestCounter()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            switch request.url {
            case "https://api.snabble-testing.io/apps/123/users":
                postCounter.increment()
                return (response, try loadResource(inBundle: .module,
                    filename: "UsersResponse-Without-Token", withExtension: "json"))
            case "https://api.snabble-testing.io/tokens?project=1&role=retailerApp":
                tokenCounter.increment()
                return (response, try loadResource(inBundle: .module,
                    filename: "Token", withExtension: "json"))
            default:
                return (HTTPURLResponse(url: request.url!, statusCode: 500,
                    httpVersion: nil, headerFields: nil)!, Data())
            }
        }

        // First call: fetches AppUser (POST) and Token (GET)
        _ = try await authenticator.validToken(withConfiguration: configuration)

        // Second call: must return the cached token without new network requests
        _ = try await authenticator.validToken(withConfiguration: configuration)

        XCTAssertEqual(postCounter.count, 1, "POST /users must not repeat after token is cached")
        XCTAssertEqual(tokenCounter.count, 1, "GET /tokens must not repeat after token is cached")
    }

    var appUser: AppUser?
    var projectId: String = "1"
}

extension AuthenticatorTests: AuthenticatorDelegate {
    func authenticator(_ authenticator: Authenticator, appUserUpdated appUser: AppUser) {
        self.appUser = appUser
    }

    func authenticator(_ authenticator: Authenticator, appUserForConfiguration configuration: SnabbleNetwork.Configuration) -> AppUser? {
        appUser
    }

    func authenticator(_ authenticator: Authenticator, projectIdForConfiguration configuration: SnabbleNetwork.Configuration) -> String? {
        projectId
    }
}
