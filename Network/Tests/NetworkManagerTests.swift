//
//  NetworkManagerTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
import Foundation
@testable import SnabbleNetwork
import Combine

final class NetworkManagerTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!
    var networkManager: NetworkManager!
    var configuration: Configuration = .init(appId: "123", appSecret: "2", domain: .production)
    var appUser: AppUser?

    override func setUpWithError() throws {
        cancellables = Set<AnyCancellable>()
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
        cancellables = nil
        networkManager = nil
    }

    func testRequestWithError() throws {
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

        let expectation = expectation(description: "register")
        networkManager.publisher(for: endpoint)
            .sink { completion in
                switch completion {
                case .failure:
                    expectation.fulfill()
                case .finished:
                    break
                }
            } receiveValue: { validation in
                XCTAssertNil(validation)
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testEndpoint() throws {
        let endpoint = Endpoints.Phone.auth(phoneNumber: "+4915119695415")

        let expectation = expectation(description: "auth")
        networkManager.publisher(for: endpoint)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTAssertThrowsError(error)
                case .finished:
                    break
                }
                expectation.fulfill()
            } receiveValue: { value in
                print("foobar")
                print(value)
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 10.0)
    }

    
}

extension NetworkManagerTests: NetworkManagerDelegate {
    func networkManager(_ networkManager: NetworkManager, appUserUpdated appUser: AppUser) {
        self.appUser = appUser
    }

    func networkManager(_ networkManager: NetworkManager, appUserForConfiguration configuration: Configuration) -> AppUser? {
        appUser
    }

    func networkManager(_ networkManager: NetworkManager, projectIdForConfiguration configuration: Configuration) -> String? {
        "123"
    }
}
