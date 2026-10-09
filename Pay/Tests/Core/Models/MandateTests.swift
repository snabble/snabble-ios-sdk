//
//  MandateTests.swift
//
//
//  Created by Andreas Osberghaus on 2023-02-24.
//

import Testing
@testable import SnabblePay

@Suite
struct MandateTests {
    @Test func testEquatable() throws {
        let mandate1 = Account.Mandate(id: "0", state: .pending, htmlText: nil)
        let mandate2 = Account.Mandate(id: "0", state: .accepted, htmlText: nil)
        let mandate3 = Account.Mandate(id: "1", state: .pending, htmlText: nil)

        #expect(mandate1 == mandate2)
        #expect(mandate1 != mandate3)
    }
}
