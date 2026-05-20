//
//  AuthenticatorTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork
import Combine

// Thread-safe counter for verifying request counts across concurrent network calls.
private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0

    var count: Int { lock.withLock { _count } }
    func increment() { lock.withLock { _count += 1 } }
}

final class AuthenticatorTests: XCTestCase {

    var authenticator: Authenticator!
    var cancellables = Set<AnyCancellable>()
    var configuration = Configuration(appId: "123", appSecret: "123-456-789", domain: .testing)
    var urlSession: URLSession = .mockSession

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
        let expectation = expectation(description: "validateToken")
        authenticator.validToken(withConfiguration: configuration)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTAssertThrowsError(error)
                }
                expectation.fulfill()
            } receiveValue: { token in
                XCTAssertNotNil(token)
            }
            .store(in: &cancellables)
#if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: 5)
#else
        wait(for: [expectation], timeout: 5)
#endif
    }

    /// Verifies that concurrent calls to validToken share a single upstream chain and
    /// therefore fire POST /users exactly once, not once per subscriber.
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

        let e1 = expectation(description: "subscriber1")
        let e2 = expectation(description: "subscriber2")
        let e3 = expectation(description: "subscriber3")

        // All three subscribe synchronously before URLSession dispatches the response,
        // so they all share the same in-flight request via Publishers.Share.
        for exp in [e1, e2, e3] {
            authenticator.validToken(withConfiguration: configuration)
                .sink { _ in exp.fulfill() } receiveValue: { _ in }
                .store(in: &cancellables)
        }

        await fulfillment(of: [e1, e2, e3], timeout: 5)
        XCTAssertEqual(postCounter.count, 1,
            "POST /users must be fired exactly once regardless of concurrent subscriber count")
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

        // First call: must fetch AppUser (POST) and Token (GET)
        let firstExpectation = expectation(description: "first call")
        authenticator.validToken(withConfiguration: configuration)
            .sink { _ in firstExpectation.fulfill() } receiveValue: { _ in }
            .store(in: &cancellables)
        await fulfillment(of: [firstExpectation], timeout: 5)

        // Second call: must return the cached token without any network requests
        let secondExpectation = expectation(description: "second call — cached")
        authenticator.validToken(withConfiguration: configuration)
            .sink { _ in secondExpectation.fulfill() } receiveValue: { _ in }
            .store(in: &cancellables)
        await fulfillment(of: [secondExpectation], timeout: 5)

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
