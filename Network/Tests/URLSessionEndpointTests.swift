//
//  URLSessionEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
import Combine
@testable import SnabbleNetwork

final class URLSessionEndpointTests: XCTestCase {

    let resourceData = try! loadResource(inBundle: .module, filename: "UsersResponse", withExtension: "json")
    let endpointUsers: Endpoint<UsersResponse> = Endpoints.AppUser.post(appId: "123-456-789", appSecret: "1")
    var cancellables = Set<AnyCancellable>()

    // MARK: - Decodable

    func testCombine() async throws {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { [unowned self] request in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.snabble.io/apps/123-456-789/users")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, resourceData)
        }

        let expectation = expectation(description: "users")
        let session = URLSession.mockSession
        session.dataTaskPublisher(for: endpointUsers)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTAssertTrue(true)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expectation.fulfill()
            } receiveValue: { usersReponse in
                XCTAssertNotNil(usersReponse)
            }
            .store(in: &cancellables)

#if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: 5)
#else
        wait(for: [expectation], timeout: 5.0)
#endif
    }

    func testCombineError() async throws {
        MockURLProtocol.error = URLError(.unknown)
        MockURLProtocol.requestHandler = nil

        let expectation = expectation(description: "users")
        let session = URLSession.mockSession
        session.dataTaskPublisher(for: endpointUsers)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTAssertTrue(true)
                case .failure(let error):
                    XCTAssertNotNil(error)
                }
                expectation.fulfill()
            } receiveValue: { credentials in
                XCTAssertNil(credentials)
            }
            .store(in: &cancellables)

#if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: 5)
#else
        wait(for: [expectation], timeout: 5.0)
#endif
    }

    func testDecodableCombineInvalidResponse() async throws {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.snabble.io/apps/123-456-789/users")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }

        let expectation = expectation(description: "register")
        let session = URLSession.mockSession
        session.dataTaskPublisher(for: endpointUsers)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTAssertTrue(true)
                case .failure(let error):
                    XCTAssertNotNil(error)
                    if case HTTPError.invalid(let response, _) = error {
                        XCTAssertEqual(response.httpStatusCode, .notFound)
                    } else {
                        XCTFail("should ne httpError invalidResponse")
                    }
                }
                expectation.fulfill()
            } receiveValue: { credentials in
                XCTAssertNil(credentials)
            }
            .store(in: &cancellables)

#if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: 5)
#else
        wait(for: [expectation], timeout: 5.0)
#endif
    }
}
