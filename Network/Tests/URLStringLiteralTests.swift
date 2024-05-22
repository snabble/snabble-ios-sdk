//
//  URL+StringLiteralTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class URLStringLiteralTests: XCTestCase {
    func test() throws {
        let url: URL = "http://www.google.de"
        XCTAssertEqual(url.absoluteString, "http://www.google.de")
    }
}
