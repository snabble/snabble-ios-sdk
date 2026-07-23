//
//  PaymentDataEncrypterTests.swift
//
//  Copyright © 2024 snabble. All rights reserved.
//

import Testing
import Security
@testable import SnabbleCore

@Suite("DERParser")
struct DERParserTests {

    // Loads a DER certificate from Core/Sources/Resources/ relative to this test file.
    private func loadCert(named name: String) throws -> SecCertificate {
        let resourcesURL = URL(fileURLWithPath: #file)
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

    // MARK: - CA certificates (self-signed, UTCTime not-before)

    @Test("staging-ca.der not-before is Nov 16 08:54:00 2022 UTC")
    func stagingCANotBefore() throws {
        let cert = try loadCert(named: "staging-ca")
        let notBefore = try #require(DERParser.notBeforeDate(of: cert))
        #expect(notBefore == utcDate(year: 2022, month: 11, day: 16, hour: 8, minute: 54, second: 0))
    }

    @Test("prod-ca.der not-before is Nov 16 08:54:07 2022 UTC")
    func prodCANotBefore() throws {
        let cert = try loadCert(named: "prod-ca")
        let notBefore = try #require(DERParser.notBeforeDate(of: cert))
        #expect(notBefore == utcDate(year: 2022, month: 11, day: 16, hour: 8, minute: 54, second: 7))
    }

    @Test("testing-ca.der not-before is Nov 16 08:35:38 2022 UTC")
    func testingCANotBefore() throws {
        let cert = try loadCert(named: "testing-ca")
        let notBefore = try #require(DERParser.notBeforeDate(of: cert))
        #expect(notBefore == utcDate(year: 2022, month: 11, day: 16, hour: 8, minute: 35, second: 38))
    }

}
