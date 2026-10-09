//
//  NetworkCoreTests.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import Testing
import Foundation
import SnabbleNetwork
@testable import SnabblePayNetwork
import TestHelper

/// All tests touching `MockURLProtocol`'s global mutable state run serially to prevent
/// cross-suite interference (Swift Testing parallelizes independent top-level suites by default).
@Suite(.serialized)
enum NetworkCoreTests {

    struct URLSessionEndpointTests {
        let errorData = try! loadResource(inBundle: .module, filename: "error-unknown", withExtension: "json")
        let resourceData = try! loadResource(inBundle: .module, filename: "register", withExtension: "json")
        let endpointRegister: Endpoint<Credentials> = Endpoints.Register.post(apiKeyValue: "123456")

        @Test func testDecodable() async throws {
            let data = resourceData
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { _ in
                let response = HTTPURLResponse(
                    url: URL(string: "https://payment.snabble.io/apps/register")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, data)
            }

            let session = URLSession.mockSession
            let credentials = try await session.data(for: endpointRegister)
            #expect(credentials.identifier.isEmpty == false)
        }

        @Test func testDecodableError() async throws {
            MockURLProtocol.error = URLError(.unknown)
            MockURLProtocol.requestHandler = nil

            let session = URLSession.mockSession
            await #expect(throws: (any Error).self) {
                _ = try await session.data(for: endpointRegister)
            }
        }

        @Test func testDecodableInvalidResponse() async throws {
            let data = errorData
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { _ in
                let response = HTTPURLResponse(
                    url: URL(string: "https://payment.snabble.io/apps/register")!,
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, data)
            }

            let session = URLSession.mockSession
            do {
                _ = try await session.data(for: endpointRegister)
                Issue.record("should have thrown")
            } catch let error as PayHTTPError {
                if case .validationError(let statusCode, let endpointError) = error {
                    #expect(statusCode == .notFound)
                    #expect(endpointError.reason == .unknown)
                } else {
                    Issue.record("should be validationError")
                }
            }
        }

        @Test func testDecodableInvalidResponseWithErrorObject() async throws {
            let data = resourceData
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { _ in
                let response = HTTPURLResponse(
                    url: URL(string: "https://payment.snabble.io/apps/register")!,
                    statusCode: 400,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, data)
            }

            let session = URLSession.mockSession
            await #expect(throws: (any Error).self) {
                _ = try await session.data(for: endpointRegister)
            }
        }
    }

    @MainActor
    final class NetworkManagerTests {
        let networkManager: SnabblePayNetwork.NetworkManager

        init() {
            networkManager = SnabblePayNetwork.NetworkManager(apiKey: "123456", credentials: nil, urlSession: .mockSession)
        }

        deinit {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = nil
        }

        @Test func testRequestWithError() async throws {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data())
            }

            let endpoint = Endpoints.Register.post(apiKeyValue: "1234")
            await #expect(throws: (any Error).self) {
                _ = try await networkManager.publisher(for: endpoint, onEnvironment: .production)
            }
        }

        @Test func testRequest() async throws {
            MockURLProtocol.error = nil
            MockURLProtocol.requestHandler = { request in
                if request.url?.path == "/apps/register" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )!
                    return (response, try loadResource(inBundle: .module, filename: "register", withExtension: "json"))
                }

                if request.url?.path == "/apps/token" {
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "application/json"]
                    )!
                    return (response, try loadResource(inBundle: .module, filename: "token", withExtension: "json"))
                }

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data())
            }

            let endpoint = Endpoints.Token.get(withCredentials: .init(identifier: "random_app_identifier", secret: "random_app_secret"))
            let token = try await networkManager.publisher(for: endpoint, onEnvironment: .production)
            #expect(token.value.isEmpty == false)
        }
    }
}
