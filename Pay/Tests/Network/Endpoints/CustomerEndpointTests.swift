//
//  CustomerEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-03-16.
//

import Testing
import Foundation
@testable import SnabblePayNetwork
@testable import SnabbleNetwork
import TestHelper

@Suite
struct CustomerEndpointTests {
    @Test func testPutEndpoint() throws {
        let endpoint = Endpoints.Customer.put(id: "123", loyaltyId: "789")
        #expect(endpoint.path == "/apps/customer")
        #expect(endpoint.method.value == "PUT")
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
        let urlRequest = try endpoint.urlRequest()
        #expect(urlRequest.url?.absoluteString == "https://payment.snabble.io/apps/customer")
    }

    @Test func testEnvironment() throws {
        #expect(Endpoints.Customer.put(id: "123", loyaltyId: "789").baseURLOverride == Environment.production.baseURL)
        #expect(Endpoints.Customer.put(id: "12312", loyaltyId: "442", onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
        #expect(Endpoints.Customer.put(id: "12312", loyaltyId: "442", onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
    }

    @Test func testDecoding() throws {
        let data = try loadResource(inBundle: .module, filename: "customer", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Customer.self, from: data)
        #expect(instance.id == "123")
        #expect(instance.loyaltyId == "456")
    }

    @Test func testDecodingEmpty() throws {
        let data = try loadResource(inBundle: .module, filename: "customer-null", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Customer.self, from: data)
        #expect(instance.id == nil)
        #expect(instance.loyaltyId == nil)
    }
}
