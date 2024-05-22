//
//  SnabblePayTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-02-01.
//

import XCTest
@testable import SnabblePay
import TestHelper

final class SnabblePayTests: XCTestCase {

    let instance: SnabblePay = SnabblePay(apiKey: "1234", credentials: nil, urlSession: .mockSession)

    private var injectedResponse: ((URLRequest) throws -> (HTTPURLResponse, Data))! = { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data())
    }

    override func setUpWithError() throws {
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = { [self] request in
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

            return try self.injectedResponse(request)
        }
    }

    override func tearDownWithError() throws {
        injectedResponse = nil
    }


    func testAccountCheckSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "account-check", withExtension: "json"))
        }
        let expectation = expectation(description: "testAccountCheckSuccess")
        instance.accountCheck(withAppUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE") { result in
            switch result {
            case let .success(accountCheck):
                XCTAssertNotNil(accountCheck)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testAccountCheckFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testAccountCheckFailure")
        instance.accountCheck(withAppUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE") { result in
            switch result {
            case let .success(accountCheck):
                XCTAssertNil(accountCheck)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testAccountsSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "accounts-many", withExtension: "json"))
        }
        let expectation = expectation(description: "testAccountsSuccess")
        instance.accounts() { result in
            switch result {
            case let .success(accounts):
                XCTAssertNotNil(accounts)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testAccountsFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testAccountsFailure")
        instance.accounts() { result in
            switch result {
            case let .success(accounts):
                XCTAssertNil(accounts)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testAccountSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "account-id", withExtension: "json"))
        }
        let expectation = expectation(description: "testAccountSuccess")
        instance.account(withId: "1") { result in
            switch result {
            case let .success(account):
                XCTAssertNotNil(account)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testAccountFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testAccountFailure")
        instance.account(withId: "1") { result in
            switch result {
            case let .success(account):
                XCTAssertNil(account)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testDeleteAccountSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "account-id", withExtension: "json"))
        }
        let expectation = expectation(description: "testDeleteAccountSuccess")
        instance.deleteAccount(withId: "1") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testDeleteAccountFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testDeleteAccountFailure")
        instance.deleteAccount(withId: "1") { result in
            switch result {
            case let .success(instance):
                XCTAssertNil(instance)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testMandateSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "mandate-pending", withExtension: "json"))
        }
        let expectation = expectation(description: "testMandateSuccess")
        instance.mandate(forAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNotNil(mandate)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testMandateFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testMandateFailure")
        instance.mandate(forAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNil(mandate)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testAcceptMandateSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "mandate-pending", withExtension: "json"))
        }
        let expectation = expectation(description: "testAcceptMandateSuccess")
        instance.acceptMandate(withId: "1", forAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNotNil(mandate)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testAcceptAccountFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testAcceptAccountFailure")
        instance.acceptMandate(withId: "1", forAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNil(mandate)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testDeclineMandateSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "mandate-accepted", withExtension: "json"))
        }
        let expectation = expectation(description: "testDeclineMandateSuccess")

        instance.declineMandate(withId: "1", forAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNotNil(mandate)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testDeclineMandateFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testDeclineMandateFailure")
        instance.declineMandate(withId: "2", forAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNil(mandate)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testSessionsSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "sessions", withExtension: "json"))
        }
        let expectation = expectation(description: "testSessionsSuccess")
        instance.sessions() { result in
            switch result {
            case let .success(result):
                XCTAssertNotNil(result)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }

    func testSessionsFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testSessionsFailure")
        instance.startSession(withAccountId: "1") { result in
            switch result {
            case let .success(result):
                XCTAssertNil(result)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testStartSessionSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "sessions-post", withExtension: "json"))
        }
        let expectation = expectation(description: "testStartSessionSuccess")
        instance.startSession(withAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNotNil(mandate)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testStartSessionFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testStartSessionFailure")
        instance.startSession(withAccountId: "1") { result in
            switch result {
            case let .success(mandate):
                XCTAssertNil(mandate)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testSessionIdSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "sessions-get", withExtension: "json"))
        }
        let expectation = expectation(description: "testSessionIDSuccess")
        instance.session(withId: "1") { result in
            switch result {
            case let .success(result):
                XCTAssertNotNil(result)
                expectation.fulfill()
            case .failure:
                XCTFail("shouldn't happen")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testSessionIdFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testSessionIdFailure")
        instance.session(withId: "1") { result in
            switch result {
            case let .success(result):
                XCTAssertNil(result)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testSessionDeleteSuccess() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, try loadResource(inBundle: .module, filename: "sessions-get", withExtension: "json"))
        }
        let expectation = expectation(description: "testSessionDeleteSuccess")
        instance.deleteSession(withId: "1") { result in
            switch result {
            case let .success(result):
                XCTAssertNotNil(result)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("shouldn't happen \(error)")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testSessionDeleteFailure() throws {
        injectedResponse = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let expectation = expectation(description: "testSessionDeleteFailure")
        instance.deleteSession(withId: "1") { result in
            switch result {
            case let .success(result):
                XCTAssertNil(result)
            case let .failure(error):
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }
}
