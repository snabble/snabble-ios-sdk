//
//  TemplateTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleSDK

class TemplateTests: XCTestCase {

    override func setUp() {
        let builtinTemplates = [
            "ean13_instore":        "2{code:5}{_}{embed:5}{ec}",
            "ean13_instore_chk":    "2{code:5}{i}{embed:5}{ec}",
            "german_print":         "4{code:2}{_:5}{embed:4}{ec}",
            "ean14_code128":        "01{code:ean14}",
            "ikea_itf14":           "{code:8}{_:6}",
            "default":              "{code:*}"
        ]

        for (id, template) in builtinTemplates {
            CodeMatcher.addTemplate("", id, template)
        }
    }

    override func tearDown() {
        CodeMatcher.clearTemplates()
    }

    func testNewlineCode() {
        let match = CodeTemplate("", "{code:*}")?.match("0000000000000\n")
        XCTAssertNotNil(match)
        XCTAssertEqual(match!.lookupCode, "0000000000000\n")
    }

    func testExtractConstants() {
        let template = CodeTemplate("", "{code=21}{_:10}{ec}")
        XCTAssertNotNil(template)
        let match = template?.match("2100000000005")
        XCTAssertNotNil(match)
        if let m = match {
            XCTAssertEqual(m.lookupCode, "21")
        }

        let noMatch = template?.match("2200000000002")
        XCTAssertNil(noMatch)
    }

    func testAlphaCode() {
        let match = CodeTemplate("", "{code:13}")?.match("0000000000ABC")
        XCTAssertNotNil(match)
        XCTAssertEqual(match!.lookupCode, "0000000000ABC")
    }

    func testTemplateParser() {
        // valid templates
        XCTAssertNotNil(CodeTemplate("", "96{code:ean13}{embed:6}{price:5}{_}"))
        XCTAssertNotNil(CodeTemplate("", "2{code:5}{i}{embed:5}{_}"))
        XCTAssertNotNil(CodeTemplate("", "01{code:ean14}"))
        XCTAssertNotNil(CodeTemplate("", "97{code:ean13}{price:6}{_}"))
        XCTAssertNotNil(CodeTemplate("", "96{code:7}{price:5}"))
        XCTAssertNotNil(CodeTemplate("", "96{_:5}{code:ean13}{_:3}"))
        XCTAssertNotNil(CodeTemplate("", "96{price:5}{ec}"))
        XCTAssertNotNil(CodeTemplate("", "{code:*}"))
        XCTAssertNotNil(CodeTemplate("", "{embed:4.3}"))

        // invalid templates
        XCTAssertNil(CodeTemplate("", "{embed:1.2.3.4}"))
        XCTAssertNil(CodeTemplate("", "96price:5}"))
        XCTAssertNil(CodeTemplate("", "96{code:**}"))
        XCTAssertNil(CodeTemplate("", "96{prize:5}"))
        XCTAssertNil(CodeTemplate("", "{prize:5}"))
        XCTAssertNil(CodeTemplate("", "96{code{ean13}{embed:6}{price:5}{_}"))
        XCTAssertNil(CodeTemplate("", "96{price:5"))
        XCTAssertNil(CodeTemplate("", "96{price:5}}"))
        XCTAssertNil(CodeTemplate("", "96{}"))
        XCTAssertNil(CodeTemplate("", "96{}{}"))
        XCTAssertNil(CodeTemplate("", "2{code:5}i}{embed:5}{_}"))
        XCTAssertNil(CodeTemplate("", "01{code:ean14}{code:4}"))
        XCTAssertNil(CodeTemplate("", "{code:abc}"))
        XCTAssertNil(CodeTemplate("", "96{i}{price:5}"))
        XCTAssertNil(CodeTemplate("", "96{i}{embed:6}"))
        XCTAssertNil(CodeTemplate("", ""))
        XCTAssertNil(CodeTemplate("", "{embed:-1}"))
        XCTAssertNil(CodeTemplate("", "{code:-1}"))
        XCTAssertNil(CodeTemplate("", "96{price:5}{ec}{_}"))
        XCTAssertNil(CodeTemplate("", "{{}}"))
        XCTAssertNil(CodeTemplate("", "{code:8{_:3}}"))
    }

    func testTemplateMatcher() {
        // valid matches
        XCTAssertNotNil(CodeTemplate("", "{code:ean13}")?.match("0000000000000"))
        XCTAssertNotNil(CodeTemplate("", "{code:ean13}")?.match("0000000000017"))
        XCTAssertNotNil(CodeTemplate("", "{code:ean13}")?.match("2957783000742"))
        XCTAssertNotNil(CodeTemplate("", "{code:ean13}")?.match("4029764001807"))

        if let template = CodeTemplate("", "{code:ean13}"), let match = template.match("0000000000000") {
            XCTAssertEqual(match.lookupCode, "0000000000000")
        }
        if let template = CodeTemplate("", "{code:ean13}"), let match = template.match("0000000000017") {
            XCTAssertEqual(match.lookupCode, "0000000000017")
        }

        XCTAssertNotNil(CodeTemplate("", "{code:ean8}")?.match("87654325"))
        XCTAssertNotNil(CodeTemplate("", "{code:8}")?.match("87654325"))
        XCTAssertNotNil(CodeTemplate("", "{code:8}")?.match("87654320"))

        XCTAssertNotNil(CodeTemplate("", "{code:ean14}")?.match("18594001694690"))
        XCTAssertNotNil(CodeTemplate("", "{code:ean14}")?.match("28000017120605"))

        if let template = CodeTemplate("", "01{code:ean14}"), let match = template.match("0128000017120605") {
            XCTAssertEqual(match.lookupCode, "28000017120605")
        }

        XCTAssertNotNil(CodeTemplate("", "96{code:ean13}{embed:6}{price:5}{_}")?.match("960000000000000111111222223"))

        // invalid matches
        XCTAssertNil(CodeTemplate("", "2{code:5}{_}{embed:5}{_}")?.match("0128000017120605"))
        XCTAssertNil(CodeTemplate("", "{code:ean13}")?.match("0000000000001"))
        XCTAssertNil(CodeTemplate("", "{code:ean13}")?.match("000000000000"))
        XCTAssertNil(CodeTemplate("", "{code:ean13}")?.match("4029764001800"))
        XCTAssertNil(CodeTemplate("", "{code:ean8}")?.match("87654320"))

        XCTAssertNil(CodeTemplate("", "96{code:ean13}{embed:6}{price:5}{_}")?.match("970000000000000111111222223"))
        XCTAssertNil(CodeTemplate("", "96{code:ean13}{embed:6}{price:5}{_}")?.match("96000000000000011111122222"))
    }

    func testEmbeddedData() {
        guard let print = CodeTemplate("", "4{code:2}{_:5}{embed:4}{_}") else {
            return XCTAssert(false, "bad template")
        }
        guard let match1 = print.match("4191234500995") else {
            return XCTAssert(false, "no match")
        }
        XCTAssertEqual(match1.embeddedData, 99)

        guard let instore = CodeTemplate("", "2{code:5}{_}{embed:5}{_}") else {
            return XCTAssert(false, "bad template")
        }
        guard let match2 = instore.match("2957783000742") else {
            return XCTAssert(false, "no match")
        }
        XCTAssertEqual(match2.embeddedData, 74)

        guard let instore2 = CodeTemplate("", "2{code:5}{_}{embed:3.2}{_}") else {
            return XCTAssert(false, "bad template")
        }
        guard let match3 = instore2.match("2957783000742") else {
            return XCTAssert(false, "no match")
        }
        guard let decimal = match3.embeddedDecimal else {
            return XCTAssert(false, "no decimal")
        }
        XCTAssertEqual(decimal.value, 74)
        XCTAssertEqual(decimal.fractionDigits, 2)
        XCTAssertEqual(decimal.integerDigits, 3)
    }

    func testEmbed100() {
        guard let e100 = CodeTemplate("", "{embed100:4}") else {
            return XCTAssert(false, "bad template")
        }
        guard let match = e100.match("1234") else {
            return XCTAssert(false, "no match")
        }
        XCTAssertEqual(match.embeddedData, 123400)
    }

    func testTemplateInternalChecksum() {
        XCTAssertNotNil(CodeTemplate("", "295778{i}{embed:5}{_}")?.match("2957783000742"))
        XCTAssertNotNil(CodeTemplate("", "{code:6}{i}{embed:5}{_}")?.match("2957783000742"))
        
        XCTAssertNil(CodeTemplate("", "295778{i}{embed:5}{_}")?.match("2957784000742"))
        XCTAssertNil(CodeTemplate("", "{code:6}{i}{embed:5}{_}")?.match("2957784000742"))

        if let template = CodeTemplate("", "295778{i}{embed:5}{_}"), let match = template.match("2957783000742") {
            XCTAssertTrue(match.isValid)
            XCTAssertEqual(match.lookupCode, "")
        }

        if let template = CodeTemplate("", "{code:6}{i}{embed:5}{_}"), let match = template.match("2957783000742") {
            XCTAssertEqual(template.expectedLength, 13)
            XCTAssertTrue(match.isValid)
            XCTAssertEqual(match.lookupCode, "295778")
        }
    }

    func testTemplateWithData() {
        guard let template = CodeTemplate("", "2{_:6}{embed:5}{ec}") else {
            return XCTAssert(false, "bad template")
        }
        guard let result = template.match("2957780000004") else {
            return XCTAssert(false, "no match")
        }

        let code = result.embed(12345)
        XCTAssertEqual(code, "2957780123451")
        XCTAssertNotNil(EAN.parse(code))
    }

    func testTemplateWithDataInternalCheck() {
        guard let template = CodeTemplate("", "2{_:5}{i}{embed:5}{ec}") else {
            return XCTAssert(false, "bad template")
        }
        guard let result = template.match("2957780000004") else {
            return XCTAssert(false, "no match")
        }

        let code = result.embed(12345)
        XCTAssertEqual(code, "2957788123453")
        XCTAssertNotNil(EAN.parse(code))
    }

    func testWasgauWeighing() {
        guard let template = CodeTemplate("", "01{code:14}15{_:6}3103{embed:3.3}10{_:*}") else {
            return XCTAssert(false, "bad template")
        }

        guard let result1 = template.match("019011531031000815060403310302028810030406") else {
            return XCTAssert(false, "no match")
        }
        XCTAssertEqual(result1.embeddedDecimal?.value, 20288)
        XCTAssertEqual(result1.lookupCode, "90115310310008")

        guard let result2 = template.match("0194036300455874150608243103012545103760551236") else {
            return XCTAssert(false, "no match")
        }
        XCTAssertEqual(result2.embeddedDecimal?.value, 12545)
        XCTAssertEqual(result2.lookupCode, "94036300455874")
    }

    func testMatcher() {
        let instore = Set([ "ean13_instore_chk", "ean13_instore" ])
        let r1 = CodeMatcher.match("2957783000742", "")
        XCTAssertEqual(r1.count, 3)

        let m1 = Set(r1.map { $0.template.id })
        XCTAssertEqual(m1.intersection(instore).count, 2)

        let r2 = CodeMatcher.match("0128000017120605", "")
        XCTAssertEqual(r2.count, 2)
        let m2 = r2.map { $0.template.id }
        XCTAssertTrue(m2.contains("ean14_code128"))
        XCTAssertTrue(m2.contains("default"))

        let r3 = CodeMatcher.match("4029764001807", "")
        XCTAssertEqual(r3.count, 2)
        let m3 = r3.map { $0.template.id }
        XCTAssertTrue(m3.contains("german_print"))
        XCTAssertTrue(m3.contains("default"))
    }

    func testDefaultMatch() {
        let r3 = CodeMatcher.match("0885580466732", "")
        XCTAssertEqual(r3.count, 1)
        let m3 = r3.map { $0.template.id }
        XCTAssertTrue(m3.contains("default"))
        XCTAssertEqual(r3[0].lookupCode, "0885580466732")
    }

    func testBizerba() {
        let template = CodeTemplate("foo", "S{_:4}{embed:5}{code:*}")!

        guard let result1 = template.match("S123412345123") else {
            return XCTAssert(false, "no match")
        }
        XCTAssertEqual(result1.embeddedData, 12345)
        XCTAssertEqual(result1.lookupCode, "123")

        guard let result2 = template.match("S1234123451234567") else {
            return XCTAssert(false, "no match")
        }
        XCTAssertEqual(result2.embeddedData, 12345)
        XCTAssertEqual(result2.lookupCode, "1234567")
    }

    func testCreateEANs() {
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore", "11111", 1),     "2111110000014")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore", "11111", 12),    "2111110000120")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore", "11111", 123),   "2111110001233")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore", "11111", 1234),  "2111110012345")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore", "11111", 12345), "2111110123454")

        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore_chk", "11111", 1),     "2111114000010")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore_chk", "11111", 12),    "2111119000121")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore_chk", "11111", 123),   "2111114001239")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore_chk", "11111", 1234),  "2111111012344")
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore_chk", "11111", 12345), "2111118123456")

        XCTAssertEqual(CodeMatcher.createInstoreEan("default", "11111", 1), nil)        // can't embed in `default`
        XCTAssertEqual(CodeMatcher.createInstoreEan("default", "", 12), nil)
        
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore", "1111", 12), nil)  // code.count != 5
        XCTAssertEqual(CodeMatcher.createInstoreEan("ean13_instore", "1", 12), nil)     // code.count != 5
    }
}
