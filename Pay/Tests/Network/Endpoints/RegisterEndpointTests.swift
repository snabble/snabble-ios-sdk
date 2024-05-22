//
//  CredentialsEndpointTest.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import XCTest
@testable import SnabblePayNetwork
import TestHelper

final class RegisterEndpointTests: XCTestCase {
    func testEndpoint() throws {
        let endpoint = Endpoints.Register.post(apiKeyValue: "123456")
        XCTAssertEqual(endpoint.path, "/apps/register")
        XCTAssertEqual(endpoint.method, .post(nil))
        XCTAssertEqual(endpoint.headerFields["snabblePayKey"], "123456")
        XCTAssertEqual(endpoint.environment, .production)
    }

    func testEnvironmentStaging() throws {
        let endpoint = Endpoints.Register.post(apiKeyValue: "123456", onEnvironment: .staging)
        XCTAssertEqual(endpoint.environment, .staging)
    }

    func testEnvironmentDevelopment() throws {
        let endpoint = Endpoints.Register.post(apiKeyValue: "123456", onEnvironment: .development)
        XCTAssertEqual(endpoint.environment, .development)
    }

    func testDecodingApp() throws {
        let registerData = try loadResource(inBundle: .module, filename: "register", withExtension: "json")
        let app = try JSONDecoder().decode(Credentials.self, from: registerData)
        XCTAssertEqual(app.identifier, "1l2z79uvnKU18hJ621hDti2Q1mckTs8633HFlUz7PCG1OalckFyKf/TzJlGcOUC4WPInc+RrKCAPLc0loJCtRw==")
        XCTAssertEqual(app.secret, "qPgwvqkVCFn+aFxljTClV7+kTe+18rOQ7Qrdp5YSethhi2X9Sp97UiDkAO3qzXgcdDi/+VazutfHxbA4SZKYWA==")
    }
}
