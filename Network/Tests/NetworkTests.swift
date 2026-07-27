//
//  NetworkTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import Testing
import Foundation
@testable import SnabbleNetwork

// Required because async let creates child tasks that capture Authenticator across concurrency boundaries.
extension Authenticator: @unchecked Sendable {}

/// All network tests run serially to prevent MockURLProtocol global state conflicts across suites.
@Suite(.serialized)
enum NetworkTests {

    // MARK: - URLSession Endpoint Tests

    struct URLSessionEndpointTests {
        let resourceData: Data
        let endpointUsers: Endpoint<UsersResponse>

        init() throws {
            resourceData = try loadResource(inBundle: .module, filename: "UsersResponse", withExtension: "json")
            endpointUsers = Endpoints.AppUser.post(appId: "123-456-789", appSecret: "1")
        }

        @Test func data() async throws {
            let data = resourceData
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { _ in
                let response = HTTPURLResponse(
                    url: URL(string: "https://api.snabble.io/apps/123-456-789/users")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, data)
            }

            let session = URLSession.mockSession
            let usersResponse = try await session.data(for: endpointUsers)
            #expect(usersResponse != nil)
        }

        @Test func dataError() async throws {
            MockURLProtocol.error = URLError(.unknown)
            MockURLProtocol.requestHandler = nil

            let session = URLSession.mockSession
            await #expect(throws: (any Error).self) {
                _ = try await session.data(for: endpointUsers)
            }
        }

        @Test func dataInvalidResponse() async throws {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { _ in
                let response = HTTPURLResponse(
                    url: URL(string: "https://api.snabble.io/apps/123-456-789/users")!,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data())
            }

            let session = URLSession.mockSession
            await #expect(throws: HTTPError.self) {
                _ = try await session.data(for: endpointUsers)
            }
        }
    }

    // MARK: - Network Manager Tests

    @MainActor
    final class NetworkManagerTests {
        let networkManager: NetworkManager
        let configuration: SnabbleNetwork.Configuration
        var appUser: AppUser?

        init() {
            let config = Configuration(appId: "123", appSecret: "2", domain: .production)
            self.configuration = config
            self.appUser = nil
            self.networkManager = NetworkManager(configuration: config, urlSession: .mockSession)
            self.networkManager.delegate = self
        }

        deinit {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = nil
        }

        @Test func requestWithError() async throws {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data())
            }

            let endpoint = Endpoints.AppUser.post(appId: configuration.appId, appSecret: configuration.appSecret)
            await #expect(throws: (any Error).self) {
                _ = try await networkManager.publisher(for: endpoint)
            }
        }

        @Test func endpoint() async {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { request in
                switch request.url {
                case "https://api.snabble.io/apps/123/users":
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )!
                    return (response, try loadResource(inBundle: .module, filename: "UsersResponse-Without-Token", withExtension: "json"))
                case "https://api.snabble.io/tokens?project=123&role=retailerApp":
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )!
                    return (response, try loadResource(inBundle: .module, filename: "Token", withExtension: "json"))
                case "https://api.snabble.io/apps/users/me/verification/phone-number":
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )!
                    return (response, Data())
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
            let endpoint = Endpoints.Phone.auth(phoneNumber: "+4915119695415")
            _ = try? await networkManager.publisher(for: endpoint)
        }
    }

    // MARK: - Authenticator Tests

    @MainActor
    final class AuthenticatorTests {
        // Thread-safe counter for verifying request counts across concurrent network calls.
        private final class RequestCounter: @unchecked Sendable {
            private let lock = NSLock()
            private var _count = 0
            var count: Int { lock.withLock { _count } }
            func increment() { lock.withLock { _count += 1 } }
        }

        let authenticator: Authenticator
        let configuration: Configuration
        var appUser: AppUser?
        var projectId: String = "1"

        init() {
            self.configuration = Configuration(appId: "123", appSecret: "123-456-789", domain: .testing)
            self.appUser = nil
            self.authenticator = Authenticator(urlSession: .mockSession)
            self.authenticator.delegate = self
        }

        deinit {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = nil
        }

        @Test func validateToken() async throws {
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
            #expect(token != nil)
        }

        /// Verifies that concurrent calls to validToken share a single in-flight task and
        /// therefore fire POST /users exactly once, not once per caller.
        @Test func concurrentValidTokenCallsFireOnlyOnePostRequest() async throws {
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

            #expect(postCounter.count == 1,
                "POST /users must be fired exactly once regardless of concurrent caller count")
        }

        /// Verifies that the token received from the first validToken call is cached and
        /// reused by subsequent calls without triggering new network requests.
        @Test func tokenIsCachedAfterFirstValidation() async throws {
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

            _ = try await authenticator.validToken(withConfiguration: configuration)
            _ = try await authenticator.validToken(withConfiguration: configuration)

            #expect(postCounter.count == 1, "POST /users must not repeat after token is cached")
            #expect(tokenCounter.count == 1, "GET /tokens must not repeat after token is cached")
        }
    }
}

// MARK: - Delegate conformances

extension NetworkTests.NetworkManagerTests: NetworkManagerDelegate {
    func networkManager(_ networkManager: NetworkManager, appUserUpdated appUser: AppUser) {
        self.appUser = appUser
    }

    func networkManager(_ networkManager: NetworkManager, appUserForConfiguration configuration: SnabbleNetwork.Configuration) -> AppUser? {
        appUser
    }

    func networkManager(_ networkManager: NetworkManager, projectIdForConfiguration configuration: SnabbleNetwork.Configuration) -> String? {
        "123"
    }
}

extension NetworkTests.AuthenticatorTests: AuthenticatorDelegate {
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
