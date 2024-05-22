//
//  File.swift
//  
//
//  Created by Andreas Osberghaus on 2023-03-16.
//

import XCTest
@testable import SnabblePayNetwork
import TestHelper

final class CustomerEndpointTests: XCTestCase {
    func testPutEndpoint() throws {
        let endpoint = Endpoints.Customer.put(id: "123", loyaltyId: "789")
        XCTAssertEqual(endpoint.path, "/apps/customer")
        XCTAssertEqual(endpoint.method.value, "PUT")
//        XCTAssertEqual(endpoint.method, .put(data(forId: "123", loyaltyId: "789")))
        XCTAssertEqual(endpoint.environment, .production)
        XCTAssertNoThrow(try endpoint.urlRequest())
        let urlRequest = try! endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://payment.snabble.io/apps/customer")
    }

    func testEnvironment() throws {
        var endpoint = Endpoints.Customer.put(id: "123", loyaltyId: "789")
        XCTAssertEqual(endpoint.environment, .production)

        endpoint = Endpoints.Customer.put(id: "12312", loyaltyId: "442", onEnvironment: .staging)
        XCTAssertEqual(endpoint.environment, .staging)

        endpoint = Endpoints.Customer.put(id: "12312", loyaltyId: "442", onEnvironment: .development)
        XCTAssertEqual(endpoint.environment, .development)
    }

    // swiftlint:disable force_try
    private func data(forId id: String, loyaltyId: String) -> Data {
        let jsonObject = [
            "id": id,
            "loyaltyId": loyaltyId
        ]
        return try! JSONSerialization.data(withJSONObject: jsonObject)
    }
    // swiftlint:enable force_try

    func testDecoding() throws {
        let data = try loadResource(inBundle: .module, filename: "customer", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Customer.self, from: data)
        XCTAssertEqual(instance.id, "123")
        XCTAssertEqual(instance.loyaltyId, "456")
    }

    func testDecodingEmpty() throws {
        let data = try loadResource(inBundle: .module, filename: "customer-null", withExtension: "json")
        let instance = try TestingDefaults.jsonDecoder.decode(Customer.self, from: data)
        XCTAssertNil(instance.id)
        XCTAssertNil(instance.loyaltyId)
    }
}
