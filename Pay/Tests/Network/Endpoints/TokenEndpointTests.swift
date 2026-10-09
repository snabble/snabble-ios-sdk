//
//  TokenEndpointTests.swift
//
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import Testing
import Foundation
@testable import SnabblePayNetwork
@testable import SnabbleNetwork
import TestHelper

@Suite
struct TokenEndpointTests {
    @Test func testEndpoint() throws {
        let endpoint = Endpoints.Token.get(withCredentials: .init(identifier: "random_app_identifier", secret: "random_app_secret"))
        #expect(endpoint.path == "/apps/token")
        var urlComponents = URLComponents()
        urlComponents.queryItems = [
            .init(name: "grant_type", value: "client_credentials"),
            .init(name: "client_id", value: "random_app_identifier"),
            .init(name: "client_secret", value: "random_app_secret"),
            .init(name: "scope", value: SnabblePayNetwork.Token.Scope.all.rawValue)
        ]
        switch endpoint.method {
        case .post(let data):
            #expect(data != nil)
            #expect(urlComponents.query == String(data: data!, encoding: .utf8))
        default:
            Issue.record("wrong method")
        }
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
        #expect(endpoint.headerFields == ["Content-Type": "application/x-www-form-urlencoded"])
        let urlRequest = try endpoint.urlRequest()
        #expect(urlRequest.url?.absoluteString == "https://payment.snabble.io/apps/token")
    }

    @Test func testEnvironment() throws {
        #expect(Endpoints.Token.get(withCredentials: .init(identifier: "random_app_identifier", secret: "random_app_secret"), onEnvironment: .staging).baseURLOverride == Environment.staging.baseURL)
        #expect(Endpoints.Token.get(withCredentials: .init(identifier: "random_app_identifier", secret: "random_app_secret"), onEnvironment: .development).baseURLOverride == Environment.development.baseURL)
    }

    @Test func testDecodingCredentials() throws {
        let data = try loadResource(inBundle: .module, filename: "token", withExtension: "json")
        let decodedObject = try TestingDefaults.jsonDecoder.decode(SnabblePayNetwork.Token.self, from: data)
        #expect(decodedObject.value == "ZMNBLHLDNJM6JI-LSW8X-Q")
        #expect(decodedObject.expiresAt == TestingDefaults.dateFormatter.date(from: "2022-12-22T12:53:55+02:00"))
        #expect(decodedObject.scope == .all)
        #expect(decodedObject.type == .bearer)
    }

    @Test func testTokenIsValid() throws {
        let tokenIsInvalid = SnabblePayNetwork.Token(value: "123", expiresAt: Date(timeIntervalSinceNow: -5), scope: .all, type: .bearer)
        #expect(tokenIsInvalid.isValid() == false)

        let tokenIsValid = SnabblePayNetwork.Token(value: "1234", expiresAt: Date(timeIntervalSinceNow: 5), scope: .all, type: .bearer)
        #expect(tokenIsValid.isValid() == true)
    }
}
