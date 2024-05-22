//
//  MandateEndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-23.
//

import XCTest
@testable import SnabblePayNetwork
import TestHelper

final class MandateEndpointTests: XCTestCase {

    func testGetEndpoint() throws {
        let endpoint = Endpoints.Accounts.Mandate.get(forAccountId: "1")
        XCTAssertEqual(endpoint.path, "/apps/accounts/1/mandate")
        XCTAssertEqual(endpoint.method, .get(nil))
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testAcceptEndpoint() throws {
        let jsonObject: [String: String] = [
            "id": "1",
            "state": "ACCEPTED"
        ]

        let endpoint = Endpoints.Accounts.Mandate.accept(mandateId: "1", forAccountId: "3")
        XCTAssertEqual(endpoint.path, "/apps/accounts/3/mandate")
        switch endpoint.method {
        case .patch(let data):
            let object = try! JSONSerialization.jsonObject(with: data!) as? [String: String]
            XCTAssertEqual(object, jsonObject)
        default:
            XCTFail("should be a patch method")
        }
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testDeclineEndpoint() throws {
        let jsonObject = [
            "id": "1",
            "state": "DECLINED"
        ]

        let endpoint = Endpoints.Accounts.Mandate.decline(mandateId: "1", forAccountId: "2")
        XCTAssertEqual(endpoint.path, "/apps/accounts/2/mandate")
        switch endpoint.method {
        case .patch(let data):
            let object = try! JSONSerialization.jsonObject(with: data!) as? [String: String]
            XCTAssertEqual(object, jsonObject)
        default:
            XCTFail("should be a patch method")
        }
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testEnvironment() throws {
        var endpoint = Endpoints.Accounts.Mandate.get(forAccountId: "1", onEnvironment: .staging)
        XCTAssertEqual(endpoint.environment, .staging)

        endpoint = Endpoints.Accounts.Mandate.accept(mandateId: "1", forAccountId: "2", onEnvironment: .development)
        XCTAssertEqual(endpoint.environment, .development)

        endpoint = Endpoints.Accounts.Mandate.decline(mandateId: "1", forAccountId: "2", onEnvironment: .development)
        XCTAssertEqual(endpoint.environment, .development)

        endpoint = Endpoints.Accounts.Mandate.get(forAccountId: "1", onEnvironment: .development)
        XCTAssertEqual(endpoint.environment, .development)

        endpoint = Endpoints.Accounts.Mandate.accept(mandateId: "1", forAccountId: "2", onEnvironment: .development)
        XCTAssertEqual(endpoint.environment, .development)

        endpoint = Endpoints.Accounts.Mandate.decline(mandateId: "1", forAccountId: "2", onEnvironment: .development)
        XCTAssertEqual(endpoint.environment, .development)
    }

    func testState() throws {
        XCTAssertEqual(Account.Mandate.State.pending.rawValue, "PENDING")
        XCTAssertEqual(Account.Mandate.State.accepted.rawValue, "ACCEPTED")
        XCTAssertEqual(Account.Mandate.State.declined.rawValue, "DECLINED")
    }

    func testDecoderAccepted() throws {
        let data = try loadResource(inBundle: .module, filename: "mandate-accepted", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Account.Mandate.self, from: data)
        XCTAssertEqual(instance.state, .accepted)
        XCTAssertNil(instance.htmlText)
    }

    func testDecoderPending() throws {
        let data = try loadResource(inBundle: .module, filename: "mandate-pending", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Account.Mandate.self, from: data)
        XCTAssertEqual(instance.state, .pending)
        XCTAssertNotNil(instance.htmlText)
    }
}
