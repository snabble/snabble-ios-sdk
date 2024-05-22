//
//  SessionEndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-01-19.
//

import XCTest
@testable import SnabblePayNetwork
import TestHelper

final class SessionEndpointTests: XCTestCase {

    let jsonData = try! JSONSerialization.data(withJSONObject: ["accountId": "1"])

    func testPostEndpoint() throws {
        let endpoint = Endpoints.Session.post(withAccountId: "1")
        XCTAssertEqual(endpoint.path, "/apps/sessions")
        XCTAssertEqual(endpoint.method, .post(jsonData))
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testGetEndpoint() throws {
        let endpoint = Endpoints.Session.get()
        XCTAssertEqual(endpoint.path, "/apps/sessions")
        XCTAssertEqual(endpoint.method, .get(nil))
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testDeleteEndpoint() throws {
        let endpoint = Endpoints.Session.delete(id: "1")
        XCTAssertEqual(endpoint.path, "/apps/sessions/1")
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testGetIdEndpoint() throws {
        let endpoint = Endpoints.Session.get(id: "1")
        XCTAssertEqual(endpoint.path, "/apps/sessions/1")
        XCTAssertEqual(endpoint.method, .get(nil))
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testEnvironmentStaging() throws {
        let endpoint1 = Endpoints.Session.post(withAccountId: "1", onEnvironment: .staging)
        XCTAssertEqual(endpoint1.environment, .staging)

        let endpoint2 = Endpoints.Session.get(id: "1", onEnvironment: .staging)
        XCTAssertEqual(endpoint2.environment, .staging)

        let endpoint3 = Endpoints.Session.delete(id: "1", onEnvironment: .staging)
        XCTAssertEqual(endpoint3.environment, .staging)

        let endpoint4 = Endpoints.Session.get(onEnvironment: .staging)
        XCTAssertEqual(endpoint4.environment, .staging)
    }

    func testEnvironmentDevelopment() throws {
        let endpoint1 = Endpoints.Session.post(withAccountId: "1", onEnvironment: .development)
        XCTAssertEqual(endpoint1.environment, .development)

        let endpoint2 = Endpoints.Session.get(id: "1", onEnvironment: .development)
        XCTAssertEqual(endpoint2.environment, .development)

        let endpoint3 = Endpoints.Session.delete(id: "1", onEnvironment: .development)
        XCTAssertEqual(endpoint3.environment, .development)

        let endpoint4 = Endpoints.Session.get(onEnvironment: .development)
        XCTAssertEqual(endpoint4.environment, .development)
    }

    func testDecodingAccountPost() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-post", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Session.self, from: jsonData)
        XCTAssertEqual(instance.id, "1")
        XCTAssertEqual(instance.token.value, "3489f@asd2")
        XCTAssertEqual(instance.createdAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:34:38Z"))
        XCTAssertEqual(instance.token.createdAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:34:38Z"))
        XCTAssertEqual(instance.token.refreshAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        XCTAssertEqual(instance.token.expiresAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:44:38Z"))
        XCTAssertNil(instance.transaction)
    }

    func testDecodingAccountPostErrorDeclined() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-post-error-declined", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Endpoints.Error.self, from: jsonData)
        XCTAssertEqual(instance.reason, Endpoints.Error.Reason.mandateNotAccepted)
        XCTAssertEqual(instance.message, "The user has to accept the mandate to start a session")
    }

    func testDecodingAccountPostError() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-post-error-unknown", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Endpoints.Error.self, from: jsonData)
        XCTAssertEqual(instance.reason, Endpoints.Error.Reason.unknown)
        XCTAssertNil(instance.message)
    }

    func testDecodingAccountGet() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-get", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Session.self, from: jsonData)
        XCTAssertEqual(instance.id, "1")
        XCTAssertEqual(instance.token.value, "token")
        XCTAssertEqual(instance.createdAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        XCTAssertEqual(instance.expiresAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:44:38Z"))
        XCTAssertEqual(instance.token.createdAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        XCTAssertEqual(instance.token.refreshAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:34:38Z"))
        XCTAssertEqual(instance.token.expiresAt, TestingDefaults.dateFormatter.date(from: "2022-12-22T09:44:38Z"))
        XCTAssertNotNil(instance.transaction)
        XCTAssertEqual(instance.transaction?.id, "1")
        XCTAssertEqual(instance.transaction?.state, .preauthorizationSuccessful)
        XCTAssertEqual(instance.transaction?.amount, 399)
        XCTAssertEqual(instance.transaction?.currencyCode, "EUR")
        XCTAssertNotNil(instance.account)
    }

    func testTransactionState() throws {
        var state: Transaction.State = .preauthorizationFailed
        XCTAssertEqual(state.rawValue, "PREAUTHORIZATION_FAILED")
        state = .aborted
        XCTAssertEqual(state.rawValue, "ABORTED")
        state = .errored
        XCTAssertEqual(state.rawValue, "ERRORED")
        state = .failed
        XCTAssertEqual(state.rawValue, "FAILED")
        state = .preauthorizationSuccessful
        XCTAssertEqual(state.rawValue, "PREAUTHORIZATION_SUCCESSFUL")
        state = .successful
        XCTAssertEqual(state.rawValue, "SUCCESSFUL")
    }
}
