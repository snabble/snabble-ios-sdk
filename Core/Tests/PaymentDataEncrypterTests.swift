//
//  PaymentDataEncrypterTests.swift
//
//  Copyright © 2024 snabble. All rights reserved.
//

import Foundation
import Testing
import Security
@testable import SnabbleCore

@Suite("DERParser")
struct DERParserTests {

    // Loads a DER certificate from Core/Sources/Resources/ relative to this test file.
    private func loadCert(named name: String) throws -> SecCertificate {
        let resourcesURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()             // Core/Tests/
            .deletingLastPathComponent()             // Core/
            .appendingPathComponent("Sources/Resources/\(name).der")

        let data = try Data(contentsOf: resourcesURL)
        guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
            Issue.record("Could not create SecCertificate from \(name).der")
            throw CertLoadError()
        }
        return cert
    }

    private struct CertLoadError: Error {}

    // Returns a Date in UTC from explicit components for use in assertions.
    private func utcDate(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        components.hour = hour; components.minute = minute; components.second = second
        components.timeZone = TimeZone(abbreviation: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - validityDates: both notBefore and notAfter in a single parse pass

    @Test("staging-ca.der validity dates")
    func stagingCAValidity() throws {
        let cert = try loadCert(named: "staging-ca")
        let dates = try #require(DERParser.validityDates(of: cert))
        #expect(dates.notBefore == utcDate(year: 2022, month: 11, day: 16, hour: 8, minute: 54, second: 0))
        #expect(dates.notAfter  == utcDate(year: 2026, month: 11, day: 15, hour: 8, minute: 54, second: 0))
    }

    @Test("prod-ca.der validity dates")
    func prodCAValidity() throws {
        let cert = try loadCert(named: "prod-ca")
        let dates = try #require(DERParser.validityDates(of: cert))
        #expect(dates.notBefore == utcDate(year: 2022, month: 11, day: 16, hour: 8, minute: 54, second: 7))
        #expect(dates.notAfter  == utcDate(year: 2026, month: 11, day: 15, hour: 8, minute: 54, second: 7))
    }

    @Test("testing-ca.der validity dates")
    func testingCAValidity() throws {
        let cert = try loadCert(named: "testing-ca")
        let dates = try #require(DERParser.validityDates(of: cert))
        #expect(dates.notBefore == utcDate(year: 2022, month: 11, day: 16, hour: 8, minute: 35, second: 38))
        #expect(dates.notAfter  == utcDate(year: 2026, month: 11, day: 15, hour: 8, minute: 35, second: 38))
    }

    // MARK: - notBeforeDate convenience wrapper

    @Test("notBeforeDate returns notBefore from validityDates")
    func notBeforeDateWrapper() throws {
        let cert = try loadCert(named: "staging-ca")
        let notBefore = try #require(DERParser.notBeforeDate(of: cert))
        #expect(notBefore == utcDate(year: 2022, month: 11, day: 16, hour: 8, minute: 54, second: 0))
    }
}
