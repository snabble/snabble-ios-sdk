//
//  URL+StringLiteralTests.swift
//  
//
//  Created by Andreas Osberghaus on 2022-12-13.
//

import XCTest
@testable import SnabblePayNetwork

final class URLStringLiteralTests: XCTestCase {
    func test() throws {
        let url: URL = "http://www.google.de"
        XCTAssertEqual(url.absoluteString, "http://www.google.de")
    }
}
