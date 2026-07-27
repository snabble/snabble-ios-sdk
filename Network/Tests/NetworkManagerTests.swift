//
//  NetworkManagerTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
import Foundation

@testable import SnabbleNetwork

@MainActor
final class NetworkManagerTests: XCTestCase {

    var networkManager: NetworkManager!
    var configuration: SnabbleNetwork.Configuration = .init(appId: "123", appSecret: "2", domain: .production)
    var appUser: AppUser?

    override func setUpWithError() throws {
        networkManager = NetworkManager(configuration: configuration, urlSession: .mockSession)
        networkManager.delegate = self

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
    }

    override func tearDownWithError() throws {
        networkManager = nil
    }

    func testRequestWithError() async throws {
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

        do {
            _ = try await networkManager.publisher(for: endpoint)
            XCTFail("Expected error but request succeeded")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testEndpoint() async throws {
        let endpoint = Endpoints.Phone.auth(phoneNumber: "+4915119695415")

        do {
            _ = try await networkManager.publisher(for: endpoint)
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

extension NetworkManagerTests: NetworkManagerDelegate {
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
