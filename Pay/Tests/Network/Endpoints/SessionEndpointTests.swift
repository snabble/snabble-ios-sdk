//
//  SessionEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-01-19.
//

import Testing
import Foundation
@testable import SnabblePayNetwork
import TestHelper

@Suite
struct SessionEndpointTests {
    let jsonData = try! JSONSerialization.data(withJSONObject: ["accountId": "1"])

    @Test func testPostEndpoint() throws {
        let endpoint = Endpoints.Session.post(withAccountId: "1")
        #expect(endpoint.path == "/apps/sessions")
        #expect(endpoint.method == .post(jsonData))
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testGetEndpoint() throws {
        let endpoint = Endpoints.Session.get()
        #expect(endpoint.path == "/apps/sessions")
        #expect(endpoint.method == .get(nil))
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testDeleteEndpoint() throws {
        let endpoint = Endpoints.Session.delete(id: "1")
        #expect(endpoint.path == "/apps/sessions/1")
        #expect(endpoint.method == .delete)
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testGetIdEndpoint() throws {
        let endpoint = Endpoints.Session.get(id: "1")
        #expect(endpoint.path == "/apps/sessions/1")
        #expect(endpoint.method == .get(nil))
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testEnvironmentStaging() throws {
        #expect(Endpoints.Session.post(withAccountId: "1", onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
        #expect(Endpoints.Session.get(id: "1", onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
        #expect(Endpoints.Session.delete(id: "1", onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
        #expect(Endpoints.Session.get(onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
    }

    @Test func testEnvironmentDevelopment() throws {
        #expect(Endpoints.Session.post(withAccountId: "1", onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
        #expect(Endpoints.Session.get(id: "1", onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
        #expect(Endpoints.Session.delete(id: "1", onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
        #expect(Endpoints.Session.get(onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
    }

    @Test func testDecodingAccountPost() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-post", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Session.self, from: jsonData)
        #expect(instance.id == "1")
        #expect(instance.token.value == "3489f@asd2")
        #expect(instance.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:34:38Z"))
        #expect(instance.token.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:34:38Z"))
        #expect(instance.token.refreshAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        #expect(instance.token.expiresAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:44:38Z"))
        #expect(instance.transaction == nil)
    }

    @Test func testDecodingAccountPostErrorDeclined() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-post-error-declined", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Endpoints.Error.self, from: jsonData)
        #expect(instance.reason == Endpoints.Error.Reason.mandateNotAccepted)
        #expect(instance.message == "The user has to accept the mandate to start a session")
    }

    @Test func testDecodingAccountPostError() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-post-error-unknown", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Endpoints.Error.self, from: jsonData)
        #expect(instance.reason == Endpoints.Error.Reason.unknown)
        #expect(instance.message == nil)
    }

    @Test func testDecodingAccountGet() throws {
        let jsonData = try loadResource(inBundle: .module, filename: "sessions-get", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Session.self, from: jsonData)
        #expect(instance.id == "1")
        #expect(instance.token.value == "token")
        #expect(instance.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        #expect(instance.expiresAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:44:38Z"))
        #expect(instance.token.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        #expect(instance.token.refreshAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:34:38Z"))
        #expect(instance.token.expiresAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:44:38Z"))
        #expect(instance.transaction != nil)
        #expect(instance.transaction?.id == "1")
        #expect(instance.transaction?.state == .preauthorizationSuccessful)
        #expect(instance.transaction?.amount == 399)
        #expect(instance.transaction?.currencyCode == "EUR")
    }

    @Test func testTransactionState() throws {
        #expect(Transaction.State.preauthorizationFailed.rawValue == "PREAUTHORIZATION_FAILED")
        #expect(Transaction.State.aborted.rawValue == "ABORTED")
        #expect(Transaction.State.errored.rawValue == "ERRORED")
        #expect(Transaction.State.failed.rawValue == "FAILED")
        #expect(Transaction.State.preauthorizationSuccessful.rawValue == "PREAUTHORIZATION_SUCCESSFUL")
        #expect(Transaction.State.successful.rawValue == "SUCCESSFUL")
    }
}
