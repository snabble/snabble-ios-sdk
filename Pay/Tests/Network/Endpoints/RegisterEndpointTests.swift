//
//  RegisterEndpointTests.swift
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
struct RegisterEndpointTests {
    @Test func testEndpoint() throws {
        let endpoint = Endpoints.Register.post(apiKeyValue: "123456")
        #expect(endpoint.path == "/apps/register")
        #expect(endpoint.method == .post(nil))
        #expect(endpoint.headerFields["snabblePayKey"] == "123456")
        #expect(endpoint.baseURLOverride == Environment.production.baseURL)
    }

    @Test func testEnvironmentStaging() throws {
        let endpoint = Endpoints.Register.post(apiKeyValue: "123456", onEnvironment: .staging)
        #expect(endpoint.baseURLOverride == Environment.staging.baseURL)
    }

    @Test func testEnvironmentDevelopment() throws {
        let endpoint = Endpoints.Register.post(apiKeyValue: "123456", onEnvironment: .development)
        #expect(endpoint.baseURLOverride == Environment.development.baseURL)
    }

    @Test func testDecodingApp() throws {
        let registerData = try loadResource(inBundle: .module, filename: "register", withExtension: "json")
        let app = try JSONDecoder().decode(Credentials.self, from: registerData)
        #expect(app.identifier == "1l2z79uvnKU18hJ621hDti2Q1mckTs8633HFlUz7PCG1OalckFyKf/TzJlGcOUC4WPInc+RrKCAPLc0loJCtRw==")
        #expect(app.secret == "qPgwvqkVCFn+aFxljTClV7+kTe+18rOQ7Qrdp5YSethhi2X9Sp97UiDkAO3qzXgcdDi/+VazutfHxbA4SZKYWA==")
    }
}
