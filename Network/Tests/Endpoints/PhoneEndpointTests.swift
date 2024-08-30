//
//  PhoneEndpointTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class PhoneEndpointTests: XCTestCase {

    let phoneNumber = "+491771234567"
    let otp = "123456"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var configuration: SnabbleNetwork.Configuration = .init(appId: "1", appSecret: "2", domain: .production)
    var appUser: AppUserDTO = .init(id: "555", secret: "123-456-789")

    func testAuth() throws {
        let endpoint = Endpoints.Phone.auth(phoneNumber: phoneNumber)
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/apps/users/me/verification/phone-number")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me/verification/phone-number")
        XCTAssertEqual(urlRequest.httpMethod, "POST")

        let data = try! JSONSerialization.data(withJSONObject: [
            "phoneNumber": phoneNumber
        ])
        XCTAssertEqual(urlRequest.httpBody, data)
    }

    func testSignIn() throws {
        let endpoint = Endpoints.Phone.signIn(phoneNumber: phoneNumber, OTP: otp)
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/apps/users/me/verification/phone-number/otp")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me/verification/phone-number/otp")
        XCTAssertEqual(urlRequest.httpMethod, "POST")

        let data = try! JSONSerialization.data(withJSONObject: [
            "otp": otp,
            "phoneNumber": phoneNumber,
            "intention": "sign-in"
        ])
        XCTAssertEqual(urlRequest.httpBody?.count, data.count)
    }
    
    func testChangePhoneNumber() throws {
        let endpoint = Endpoints.Phone.changePhoneNumber(phoneNumber: phoneNumber, OTP: otp)
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "POST")
        XCTAssertEqual(endpoint.path, "/apps/users/me/verification/phone-number/otp")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me/verification/phone-number/otp")
        XCTAssertEqual(urlRequest.httpMethod, "POST")

        let data = try! JSONSerialization.data(withJSONObject: [
            "otp": otp,
            "phoneNumber": phoneNumber,
            "intention": "change-phone-number"
        ])
        XCTAssertEqual(urlRequest.httpBody?.count, data.count)
    }

    func testDelete() throws {
        let endpoint = Endpoints.Phone.delete()
        XCTAssertEqual(endpoint.domain, .production)
        XCTAssertEqual(endpoint.method.value, "DELETE")
        XCTAssertEqual(endpoint.path, "/apps/users/me/phone-number")
        XCTAssertNil(endpoint.token)
        let urlRequest = try endpoint.urlRequest()
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://api.snabble.io/apps/users/me/phone-number")
        XCTAssertEqual(urlRequest.httpMethod, "DELETE")
    }

}
