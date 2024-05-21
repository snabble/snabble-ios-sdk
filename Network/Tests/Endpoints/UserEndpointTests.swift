//
//  UserEndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2024-02-16.
//

import XCTest
@testable import SnabbleNetwork

final class UserEndpointTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    var configuration: Configuration = .init(appId: "1", appSecret: "2", domain: .production)

    func testMe() throws {
        let endpoint = Endpoints.User.me()
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "GET")
        XCTAssertEqual(endpoint.path, "/apps/users/me")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me")
        XCTAssertEqual(urlRequest.httpMethod, "GET")
    }

    func testUpdate() throws {
        let details = User.Details(firstName: "Foo", 
                                   lastName: "Bar",
                                   email: "foo@bar.com",
                                   dateOfBirth: "1970-01-01",
                                   street: "123 Main Street",
                                   zip: "98765",
                                   city: "Basin City",
                                   country: "Nowhereland",
                                   state: nil)
        let endpoint = Endpoints.User.update(details: details)
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "PUT")
        XCTAssertEqual(endpoint.path, "/apps/users/me/details")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me/details")
        XCTAssertEqual(urlRequest.httpMethod, "PUT")

        let data = try! JSONSerialization.data(withJSONObject: [
            "firstName": "Foo",
            "lastName": "Bar",
            "email": "foo@bar.com",
            "dateOfBirth": "1970-01-01",
            "street": "123 Main Street",
            "zip": "98765",
            "city": "Basin City",
            "country": "Nowhereland"
        ])
        XCTAssertEqual(urlRequest.httpBody?.count, data.count)
    }

    func testConsent() throws {
        let consent = User.Consent(version: "1")
        let endpoint = Endpoints.User.update(consent: consent)
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/apps/users/me/consents")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me/consents")
        XCTAssertEqual(urlRequest.httpMethod, "POST")

        let data = try! JSONSerialization.data(withJSONObject: [
            "version": "1.0"
        ])
        XCTAssertEqual(urlRequest.httpBody?.count, data.count)

    }

    func testDelete() throws {
        let endpoint = Endpoints.User.erase()
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/apps/users/me/erase")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me/erase")
        XCTAssertEqual(urlRequest.httpMethod, "POST")
    }

}
