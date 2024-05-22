//
//  AuthenticatorTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork
import Combine

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

    var appUser: AppUser?
    var projectId: String = "1"
}

extension AuthenticatorTests: AuthenticatorDelegate {
    func authenticator(_ authenticator: Authenticator, appUserUpdated appUser: AppUser) {
        self.appUser = appUser
    }

    func authenticator(_ authenticator: Authenticator, appUserForConfiguration configuration: Configuration) -> AppUser? {
        appUser
    }

    func authenticator(_ authenticator: Authenticator, projectIdForConfiguration configuration: Configuration) -> String? {
        projectId
    }
}
