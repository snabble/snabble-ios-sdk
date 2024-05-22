//
//  URLSessionEndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import XCTest
import Combine
@testable import SnabblePayNetwork
import TestHelper

final class URLSessionEndpointTests: XCTestCase {

    let errorData = try! loadResource(inBundle: .module, filename: "error-unknown", withExtension: "json")
    let resourceData = try! loadResource(inBundle: .module, filename: "register", withExtension: "json")
    let endpointRegister: Endpoint<Credentials> = Endpoints.Register.post(apiKeyValue: "123456")
    let endpointData: Endpoint<Data> = .init(path: "/apps/register", method: .get(nil))
    var cancellables = Set<AnyCancellable>()

    // MARK: - Decodable

    func testDecodableCombine() async throws {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { [unowned self] request in
            let response = HTTPURLResponse(
                url: URL(string: "https://payment.snabble.io/apps/register")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, resourceData)
        }

        let expectation = expectation(description: "register")
        let session = URLSession.mockSession
        session.publisher(for: endpointRegister)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTAssertTrue(true)
                case .failure(let error):
                    XCTAssertNil(error)
                }
                expectation.fulfill()
            } receiveValue: { credentials in
                XCTAssertNotNil(credentials)
            }
            .store(in: &cancellables)

#if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: 5)
#else
        wait(for: [expectation], timeout: 5.0)
#endif
    }

    func testDecodableCombineError() async throws {
        MockURLProtocol.error = URLError(.unknown)
        MockURLProtocol.requestHandler = nil

        let expectation = expectation(description: "register")
        let session = URLSession.mockSession
        session.publisher(for: endpointRegister)
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
        MockURLProtocol.requestHandler = { [unowned self] request in
            let response = HTTPURLResponse(
                url: URL(string: "https://payment.snabble.io/apps/register")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, errorData)
        }

        let expectation = expectation(description: "register")
        let session = URLSession.mockSession
        session.publisher(for: endpointRegister)
            .sink { completion in
                switch completion {
                case .finished:
                    XCTAssertTrue(true)
                case .failure(let error):
                    XCTAssertNotNil(error)
                    if case APIError.validationError(let statusCode, let endpointError) = error {
                        XCTAssertEqual(statusCode, .notFound)
                        XCTAssertEqual(endpointError.reason, .unknown)
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

    func testDecodableCombineInvalidResponseWithErrorObject() async throws {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { [unowned self] request in
            let response = HTTPURLResponse(
                url: URL(string: "https://payment.snabble.io/apps/register")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, resourceData)
        }

        let expectation = expectation(description: "register")
        let session = URLSession.mockSession
        session.publisher(for: endpointRegister)
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
}
