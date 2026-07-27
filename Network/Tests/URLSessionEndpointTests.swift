//
//  URLSessionEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class URLSessionEndpointTests: XCTestCase {

    let resourceData = try! loadResource(inBundle: .module, filename: "UsersResponse", withExtension: "json")
    let endpointUsers: Endpoint<UsersResponse> = Endpoints.AppUser.post(appId: "123-456-789", appSecret: "1")

    func testData() async throws {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { [self] request in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.snabble.io/apps/123-456-789/users")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, resourceData)
        }

        let session = URLSession.mockSession
        let usersResponse = try await session.data(for: endpointUsers)
        XCTAssertNotNil(usersResponse)
    }

    func testDataError() async throws {
        MockURLProtocol.error = URLError(.unknown)
        MockURLProtocol.requestHandler = nil

        let session = URLSession.mockSession
        do {
            _ = try await session.data(for: endpointUsers)
            XCTFail("Expected URLError but request succeeded")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testDataInvalidResponse() async throws {
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

        let session = URLSession.mockSession
        do {
            _ = try await session.data(for: endpointUsers)
            XCTFail("Expected HTTPError but request succeeded")
        } catch let HTTPError.invalid(response, _) {
            XCTAssertEqual(response.httpStatusCode, .notFound)
        } catch {
            XCTFail("Expected HTTPError.invalid but got \(error)")
        }
    }
}
