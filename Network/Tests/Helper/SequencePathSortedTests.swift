//
//  SequencePathSortedTests.swift
//  
//
//  Created by Andreas Osberghaus on 2023-05-15.
//

import XCTest
@testable import SnabbleNetwork

final class SequencePathSortedTests: XCTestCase {

    func testSortBy() throws {
        let queryItems: [URLQueryItem] = [
            .init(name: "foobar", value: "1"),
            .init(name: "barfoo", value: "100"),
            .init(name: "check", value: "200")
        ]
        XCTAssertEqual(queryItems.sorted(by: \.name), [
            .init(name: "barfoo", value: "100"),
            .init(name: "check", value: "200"),
            .init(name: "foobar", value: "1")
        ])
    }

    func testSortByUsing() throws {
        let queryItems: [URLQueryItem] = [
            .init(name: "foobar", value: "1"),
            .init(name: "barfoo", value: "100"),
            .init(name: "check", value: "200")
        ]

        XCTAssertEqual(queryItems.sorted(by: \.name, using: >), [
            .init(name: "foobar", value: "1"),
            .init(name: "check", value: "200"),
            .init(name: "barfoo", value: "100"),
        ])
    }

}
