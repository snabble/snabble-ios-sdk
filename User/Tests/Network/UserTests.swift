//
//  UserTests.swift
//
//
//  Created by Andreas Osberghaus on 2024-02-16.
//

import XCTest
@testable import SnabbleNetwork

final class UserTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMeParsing() throws {
        let url = Bundle.module.url(forResource: "Me", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let user = try Endpoints.jsonDecoder.decode(User.self, from: data)
        XCTAssertEqual(user.id, "a10cd49b-994b-4d88-b5b9-f3a4edc49929")
    }
    
    func testDetailsParsing() throws {
        let url = Bundle.module.url(forResource: "Details", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let details = try Endpoints.jsonDecoder.decode(User.Details.self, from: data)
        XCTAssertEqual(details, User.Details(firstName: "Bob", 
                                             lastName: "Biscuit",
                                             email: "bobby@example.com",
                                             dateOfBirth: "1970-01-01",
                                             street: "123 Main Street",
                                             zip: "98765",
                                             city: "Basin City",
                                             country: "Nowhereland",
                                             state: nil))
    }

    func testConsentParsing() throws {
        let url = Bundle.module.url(forResource: "Consent", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let consent = try Endpoints.jsonDecoder.decode(User.Consent.self, from: data)
        XCTAssertEqual(consent, User.Consent(version: "2.1"))
        
        let myUrl = Bundle.module.url(forResource: "Me", withExtension: "json")!
        let myData = try Data(contentsOf: myUrl)
        let myUser = try Endpoints.jsonDecoder.decode(User.self, from: myData)
        if let myVersion = myUser.consent?.version {
            XCTAssertTrue(myVersion < consent.version)
            XCTAssertFalse(myVersion == consent.version)
        }
    }
}
