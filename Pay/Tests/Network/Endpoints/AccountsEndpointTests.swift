//
//  AccountsEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-20.
//

import Testing
import Foundation
@testable import SnabblePayNetwork
import TestHelper

@Suite
struct AccountsEndpointTests {
    @Test func testCheckEndpoint() throws {
        let endpoint = Endpoints.Accounts.check(appUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE")
        #expect(endpoint.path == "/apps/accounts/check")
        #expect(endpoint.method == .get([
            .init(name: "appUri", value: "snabble-pay://account/check"),
            .init(name: "countryCode", value: "DE"),
            .init(name: "city", value: "Bonn")
        ]))
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
        let urlRequest = try endpoint.urlRequest()
        #expect(urlRequest.url?.absoluteString == "https://payment.snabble.io/apps/accounts/check?appUri=snabble-pay://account/check&city=Bonn&countryCode=DE")
    }

    @Test func testGetEndpoint() throws {
        let endpoint = Endpoints.Accounts.get()
        #expect(endpoint.path == "/apps/accounts")
        #expect(endpoint.method == .get(nil))
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testGetIdEndpoint() throws {
        let endpoint = Endpoints.Accounts.get(id: "1")
        #expect(endpoint.path == "/apps/accounts/1")
        #expect(endpoint.method == .get(nil))
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testDeleteIdEndpoint() throws {
        let endpoint = Endpoints.Accounts.delete(id: "1")
        #expect(endpoint.path == "/apps/accounts/1")
        #expect(endpoint.method == .delete)
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testEnvironment() throws {
        #expect(Endpoints.Accounts.get(id: "1", onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
        #expect(Endpoints.Accounts.get(onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
        #expect(Endpoints.Accounts.delete(id: "1", onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
        #expect(Endpoints.Accounts.check(appUri: "snabble-pay://account/check", city: "Bonn", countryCode: "DE", onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
    }

    @Test func testAccountCheckDecoding() throws {
        let data = try loadResource(inBundle: .module, filename: "account-check", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Account.Check.self, from: data)
        #expect(instance.validationURL == "https://link.tink.com/1.0/account-check/?client_id=fcba35b7bf174d30bb7ce83c1870483a&redirect_uri=https%3A%2F%2Fpayments.snabble.io%2Fcallback&market=DE&locale=en_US&state=c6a1f37a-aefd-47e4-afbb-4baf0dcf7d30")
        #expect(instance.appUri == "snabble-pay://account/check")
    }

    @Test func testDecodingEmpty() throws {
        let data = try loadResource(inBundle: .module, filename: "accounts-empty", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode([Account].self, from: data)
        #expect(instance.isEmpty)
    }

    @Test func testDecodingOne() throws {
        let data = try loadResource(inBundle: .module, filename: "accounts-one", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode([Account].self, from: data)
        #expect(instance.count == 1)
        #expect(instance.first?.id == "1")
        #expect(instance.first?.name == "John Doe's Account")
        #expect(instance.first?.holderName == "John Doe")
        #expect(instance.first?.currencyCode == "EUR")
        #expect(instance.first?.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        #expect(instance.first?.bank == "Bank Name")
        #expect(instance.first?.iban == "DE123**********")
        #expect(instance.first?.mandateState == .missing)
    }

    @Test func testDecodingMany() throws {
        let data = try loadResource(inBundle: .module, filename: "accounts-many", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode([Account].self, from: data)
        #expect(instance.count == 2)
        #expect(instance.first?.id == "1")
        #expect(instance.first?.name == "John Doe's Account")
        #expect(instance.first?.holderName == "John Doe")
        #expect(instance.first?.currencyCode == "EUR")
        #expect(instance.first?.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        #expect(instance.first?.bank == "Bank Name")
        #expect(instance.first?.iban == "DE123**********")
        #expect(instance.first?.mandateState == .accepted)
        #expect(instance.last?.id == "2")
        #expect(instance.last?.name == "Jana Doe's Account")
        #expect(instance.last?.holderName == "Jana Doe")
        #expect(instance.last?.currencyCode == "EUR")
        #expect(instance.last?.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T10:24:38Z"))
        #expect(instance.last?.bank == "Bank Name")
        #expect(instance.last?.iban == "DE123**********")
        #expect(instance.last?.mandateState == .declined)
    }

    @Test func testDecodingID() throws {
        let data = try loadResource(inBundle: .module, filename: "account-id", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Account.self, from: data)
        #expect(instance.id == "1")
        #expect(instance.name == "John Doe's Account")
        #expect(instance.holderName == "John Doe")
        #expect(instance.currencyCode == "EUR")
        #expect(instance.createdAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T09:24:38Z"))
        #expect(instance.bank == "Bank Name")
        #expect(instance.iban == "DE123**********")
        #expect(instance.mandateState == .accepted)
    }
}
