//
//  MandateEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-01-23.
//

import Testing
import Foundation
@testable import SnabblePayNetwork
import TestHelper

@Suite
struct MandateEndpointTests {
    @Test func testGetEndpoint() throws {
        let endpoint = Endpoints.Accounts.Mandate.get(forAccountId: "1")
        #expect(endpoint.path == "/apps/accounts/1/mandate")
        #expect(endpoint.method == .get(nil))
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testAcceptEndpoint() throws {
        let jsonObject: [String: String] = ["id": "1", "state": "ACCEPTED"]

        let endpoint = Endpoints.Accounts.Mandate.accept(mandateId: "1", forAccountId: "3")
        #expect(endpoint.path == "/apps/accounts/3/mandate")
        switch endpoint.method {
        case .patch(let data):
            let object = try JSONSerialization.jsonObject(with: data!) as? [String: String]
            #expect(object == jsonObject)
        default:
            Issue.record("should be a patch method")
        }
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testDeclineEndpoint() throws {
        let jsonObject = ["id": "1", "state": "DECLINED"]

        let endpoint = Endpoints.Accounts.Mandate.decline(mandateId: "1", forAccountId: "2")
        #expect(endpoint.path == "/apps/accounts/2/mandate")
        switch endpoint.method {
        case .patch(let data):
            let object = try JSONSerialization.jsonObject(with: data!) as? [String: String]
            #expect(object == jsonObject)
        default:
            Issue.record("should be a patch method")
        }
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testEnvironment() throws {
        #expect(Endpoints.Accounts.Mandate.get(forAccountId: "1", onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
        #expect(Endpoints.Accounts.Mandate.accept(mandateId: "1", forAccountId: "2", onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
        #expect(Endpoints.Accounts.Mandate.decline(mandateId: "1", forAccountId: "2", onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
    }

    @Test func testState() throws {
        #expect(Account.Mandate.State.pending.rawValue == "PENDING")
        #expect(Account.Mandate.State.accepted.rawValue == "ACCEPTED")
        #expect(Account.Mandate.State.declined.rawValue == "DECLINED")
    }

    @Test func testDecoderAccepted() throws {
        let data = try loadResource(inBundle: .module, filename: "mandate-accepted", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Account.Mandate.self, from: data)
        #expect(instance.state == .accepted)
        #expect(instance.htmlText == nil)
    }

    @Test func testDecoderPending() throws {
        let data = try loadResource(inBundle: .module, filename: "mandate-pending", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Account.Mandate.self, from: data)
        #expect(instance.state == .pending)
        #expect(instance.htmlText != nil)
    }
}
