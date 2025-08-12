//
//  QRCodeTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleCore

class QRCodeTests: XCTestCase {
    var regularItems = [CartItem]()
    var restrictedItems = [CartItem]()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let APPID = "snabble-sdk-demo-app-oguh3x"
        let APPSECRET = "2TKKEG5KXWY6DFOGTZKDUIBTNIRVCYKFZBY32FFRUUWIUAFEIBHQ===="
        let config = SnabbleCore.Config(appId: APPID, secret: APPSECRET)
        Snabble.setup(config: config, completion: { _ in })
        
        self.regularItems = {
            (0..<10).map { i in
                let product = Product(sku: "\(i)", name: "\(i)", listPrice: 1, type: .singleItem)
                let code = ScannedCode(scannedCode: "\(i)", templateId: "default", lookupCode: "\(i)")
                return CartItem(1, product , code, nil, .up)
            }
        }()

        self.restrictedItems = {
            (0..<10).map { i in
                let product = Product(sku: "r\(i)", name: "r\(i)", listPrice: 2, type: .singleItem, saleRestriction: .age(18))
                let code = ScannedCode(scannedCode: "r\(i)", templateId: "default", lookupCode: "r\(i)")
                return CartItem(1, product , code, nil, .up)
            }
        }()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - test simple codes

    func testQrCode_simple1() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().forEach { cart.add($0) }
        restrictedItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 3, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<0,1,NEXT>", "<2,3,NEXT>", "<4,5,NEXT>", "<6,7,NEXT>", "<8,9,CHECK>",
                                "<r0,r1,NEXT>", "<r2,r3,NEXT>", "<r4,r5,NEXT>", "<r6,r7,NEXT>", "<r8,r9,END>"])
    }

    func testQrCode_simple1card() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "CARD"

        regularItems.reversed().forEach { cart.add($0) }
        restrictedItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 3, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<CARD,0,NEXT>", "<1,2,NEXT>", "<3,4,NEXT>", "<5,6,NEXT>", "<7,8,NEXT>", "<9,CHECK>",
                                "<r0,r1,NEXT>", "<r2,r3,NEXT>", "<r4,r5,NEXT>", "<r6,r7,NEXT>", "<r8,r9,END>"])
    }

    func testQrCode_simple2() {
        let cart = Mock.shoppingCart()

        restrictedItems.reversed().forEach { cart.add($0) }
        regularItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 45,
                                  finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<0,1,2,3,4,5,6,7,8,9,CHECK>",
                                "<r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,END>"])
    }

    func testQrCode_simple2card() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "CARD"

        restrictedItems.reversed().forEach { cart.add($0) }
        regularItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 45, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<CARD,0,1,2,3,4,5,6,7,8,9,CHECK>",
                                "<r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,END>"])
    }

    func testQrCode_simple3() {
        let cart = Mock.shoppingCart()

        restrictedItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 45, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<CHECK>",
                                "<r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,END>"])
    }

    func testQrCode_simple3card() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "CARD"

        restrictedItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 45, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<CHECK>",
                                "<CARD,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,END>"])
    }

    func testQrCode_simple4() {
        let cart = Mock.shoppingCart()

        restrictedItems.reversed().forEach { cart.add($0) }
        regularItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 45)

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<0,1,2,3,4,5,6,7,8,9,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9>"])
    }

    func testQrCode_simple5() {
        let cart = Mock.shoppingCart()

        restrictedItems.reversed().forEach { cart.add($0) }
        regularItems.reversed().forEach { cart.add($0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 15)

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<0,1,2,3,4,5,6,7,8,9>", "<r0,r1,r2,r3,r4,r5,r6,r7,r8,r9>"])
    }

    func testQrCode_simple7() {
        let cart = Mock.shoppingCart()

        restrictedItems.reversed().prefix(1).forEach { cart.add($0); cart.setQuantity(10, for: $0) }
        regularItems.reversed().prefix(1).forEach { cart.add($0); cart.setQuantity(10, for: $0) }

        let config = QRCodeConfig(format: .simple, prefix: "<", separator: ",", suffix: ">", maxCodes: 15)

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "<9,9,9,9,9,9,9,9,9,9>", "<r9,r9,r9,r9,r9,r9,r9,r9,r9,r9>"])
    }

    func testQrCode_knauber() {
        let cart = Mock.shoppingCart()

        let item1 = regularItems[0]
        cart.add(item1)
        cart.setQuantity(2, for: item1)

        let item2 = regularItems[1]
        cart.add(item2)
        cart.setQuantity(3, for: item2)

        let config = QRCodeConfig(format: .simple, prefix: "", separator: "\n", suffix: "", maxCodes: 45, finalCode: "END")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "1\n1\n1\n0\n0\nEND" ])
    }

    func testQrCode_edeka() {
        let cart = Mock.shoppingCart()

        let item1 = regularItems[0]
        cart.add(item1)
        cart.setQuantity(2, for: item1)

        let item2 = regularItems[1]
        cart.add(item2)
        cart.setQuantity(3, for: item2)

        let config = QRCodeConfig(format: .simple, prefix: "XE", separator: "XE", suffix: "XZ", maxCodes: 45, finalCode: "fin", nextCode: "nxt", nextCodeWithCheck: "chk")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [ "XE1XE1XE1XE0XE0XEfinXZ" ])
    }

    func testQrCode_edeka2() {
        let cart = Mock.shoppingCart()

        let item1 = regularItems[0]
        cart.add(item1)
        cart.setQuantity(20, for: item1)

        let item2 = regularItems[1]
        cart.add(item2)
        cart.setQuantity(30, for: item2)

        let config = QRCodeConfig(format: .simple, prefix: "XE", separator: "XE", suffix: "XZ", maxCodes: 45, finalCode: "fin", nextCode: "nxt", nextCodeWithCheck: "chk")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XE1XEnxtXZ",
            "XE1XE1XE1XE1XE1XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XE0XEfinXZ" ])
    }

    func testQrCode_edeka3() {
        let cart = Mock.shoppingCart()

        let item1 = regularItems[0]
        cart.add(item1)
        cart.setQuantity(12, for: item1)

        let item2 = restrictedItems[1]
        cart.add(item2)
        cart.setQuantity(15, for: item2)

        let config = QRCodeConfig(format: .simple, prefix: "XE", separator: "XE", suffix: "XZ", maxCodes: 10, finalCode: "fin", nextCode: "nxt", nextCodeWithCheck: "chk")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "XE0XE0XE0XE0XE0XE0XE0XE0XE0XEchkXZ",
            "XEr1XEr1XEr1XEr1XEr1XEr1XEr1XEr1XEr1XEnxtXZ",
            "XEr1XEr1XEr1XEr1XEr1XEr1XE0XE0XE0XEfinXZ" ])
    }

    // MARK: - test CSV codes

    func testQrCode_csv1() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(5).forEach { cart.add($0); cart.add($0) }
        restrictedItems.reversed().prefix(5).forEach { cart.add($0); cart.add($0); cart.add($0) }

        let config = QRCodeConfig(format: .csv, prefix: "", separator: "⏹", suffix: "", maxCodes: 3, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "snabble;1;5⏹2;5⏹2;6⏹1;NEXT",
            "snabble;2;5⏹2;7⏹2;8⏹1;CHECK",
            "snabble;3;5⏹3;r5⏹3;r6⏹1;NEXT",
            "snabble;4;5⏹3;r7⏹3;r8⏹1;NEXT",
            "snabble;5;5⏹3;r9⏹2;9⏹1;END"
        ])
    }

    func testQrCode_csv1_card() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "CARD"

        regularItems.reversed().prefix(4).forEach { cart.add($0); cart.add($0) }
        restrictedItems.reversed().prefix(5).forEach { cart.add($0); cart.add($0); cart.add($0) }

        let config = QRCodeConfig(format: .csv, prefix: "", separator: "⏹", suffix: "", maxCodes: 3, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "snabble;1;5⏹1;CARD⏹2;6⏹1;NEXT",
            "snabble;2;5⏹2;7⏹2;8⏹1;CHECK",
            "snabble;3;5⏹3;r5⏹3;r6⏹1;NEXT",
            "snabble;4;5⏹3;r7⏹3;r8⏹1;NEXT",
            "snabble;5;5⏹3;r9⏹2;9⏹1;END" ])
    }

    func testQrCode_csv2() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(5).forEach { cart.add($0); cart.add($0) }
        restrictedItems.reversed().prefix(5).forEach { cart.add($0); cart.add($0); cart.add($0) }

        let config = QRCodeConfig(format: .csv, prefix: "", separator: "⏹", suffix: "", maxCodes: 3, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: "id").generateCodes()

        XCTAssertEqual(codes, [
            "snabble;1;5;id⏹2;5⏹2;6⏹1;NEXT",
            "snabble;2;5;id⏹2;7⏹2;8⏹1;CHECK",
            "snabble;3;5;id⏹3;r5⏹3;r6⏹1;NEXT",
            "snabble;4;5;id⏹3;r7⏹3;r8⏹1;NEXT",
            "snabble;5;5;id⏹3;r9⏹2;9⏹1;END"
        ])
    }

    func testQrCode_csv_no_id() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(2).forEach { cart.add($0); cart.add($0) }

        let config = QRCodeConfig(format: .csv_globus, prefix: "", separator: "⏹", suffix: "", maxCodes: 3, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: "id").generateCodes()

        XCTAssertEqual(codes, [
            "snabble;⏹2;8⏹2;9⏹1;END"
        ])
    }

    func testQrCode_csv1_globus() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(5).forEach { cart.add($0); cart.add($0) }
        restrictedItems.reversed().prefix(5).forEach { cart.add($0); cart.add($0); cart.add($0) }

        let config = QRCodeConfig(format: .csv_globus, prefix: "", separator: "⏹", suffix: "", maxCodes: 3, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "snabble;⏹2;5⏹2;6⏹1;NEXT",
            "snabble;⏹2;7⏹2;8⏹1;CHECK",
            "snabble;⏹3;r5⏹3;r6⏹1;NEXT",
            "snabble;⏹3;r7⏹3;r8⏹1;NEXT",
            "snabble;⏹3;r9⏹2;9⏹1;END" ])
    }

    // MARK: -- IKEA

    func testQrCode_ikea1() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(5).forEach { cart.add($0) }

        let config = QRCodeConfig(format: .ikea, maxChars: 500)

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "9100003\u{1D}1001\u{1D}2405\u{1D}2406\u{1D}2407\u{1D}2408\u{1D}2409" ])
    }

    func testQrCode_ikea1_card() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "CARD"

        regularItems.reversed().prefix(5).forEach { cart.add($0) }
        cart.setQuantity(3, at: 0)

        let config = QRCodeConfig(format: .ikea, maxChars: 500)

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "9100003\u{1D}1001\u{1D}92CARD\u{1D}2405\u{1D}2405\u{1D}2405\u{1D}2406\u{1D}2407\u{1D}2408\u{1D}2409" ])
    }

    func testQrCode_ikea2() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(5).forEach { cart.add($0) }

        let max = 30
        let config = QRCodeConfig(format: .ikea, maxChars: max)

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "9100003\u{1D}1002\u{1D}2405\u{1D}2406\u{1D}2407",
            "9100003\u{1D}1002\u{1D}2408\u{1D}2409" ])
        codes.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }
    }

    func testQrCode_ikea2_card() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "CARD"

        regularItems.reversed().prefix(5).forEach { cart.add($0) }

        let max = 30
        let config = QRCodeConfig(format: .ikea, maxChars: max)

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "9100003\u{1D}1002\u{1D}92CARD\u{1D}2405\u{1D}2406",
            "9100003\u{1D}1002\u{1D}2407\u{1D}2408\u{1D}2409" ])
        codes.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }
    }

    func testQrCode_ikea3() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(5).forEach { cart.add($0) }
        restrictedItems.reversed().prefix(5).forEach { cart.add($0) }

        let max = 300
        let config = QRCodeConfig(format: .ikea, maxChars: max, finalCode: "END", nextCodeWithCheck: "NEXT")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "9100003\u{1D}1002\u{1D}2405\u{1D}2406\u{1D}2407\u{1D}2408\u{1D}2409\u{1D}240NEXT",
            "9100003\u{1D}1002\u{1D}240r5\u{1D}240r6\u{1D}240r7\u{1D}240r8\u{1D}240r9\u{1D}240END" ])

        codes.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }
    }

    func testQrCode_ikea4() {
        let cart = Mock.shoppingCart()

        regularItems.reversed().prefix(5).forEach { cart.add($0); cart.setQuantity(5, for: $0) }
        restrictedItems.reversed().prefix(5).forEach { cart.add($0); cart.setQuantity(5, for: $0) }

        let max = 50
        let config = QRCodeConfig(format: .ikea, maxChars: max, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "9100003\u{1D}1012\u{1D}2405\u{1D}2405\u{1D}2405\u{1D}2405\u{1D}2405\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}2406\u{1D}2406\u{1D}2406\u{1D}2406\u{1D}2406\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}2407\u{1D}2407\u{1D}2407\u{1D}2407\u{1D}2407\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}2408\u{1D}2408\u{1D}2408\u{1D}2408\u{1D}2408\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}2409\u{1D}2409\u{1D}2409\u{1D}2409\u{1D}2409\u{1D}240CHECK",
            "9100003\u{1D}1012\u{1D}240r5\u{1D}240r5\u{1D}240r5\u{1D}240r5\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}240r5\u{1D}240r6\u{1D}240r6\u{1D}240r6\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}240r6\u{1D}240r6\u{1D}240r7\u{1D}240r7\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}240r7\u{1D}240r7\u{1D}240r7\u{1D}240r8\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}240r8\u{1D}240r8\u{1D}240r8\u{1D}240r8\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}240r9\u{1D}240r9\u{1D}240r9\u{1D}240r9\u{1D}240NEXT",
            "9100003\u{1D}1012\u{1D}240r9\u{1D}240END"
        ])

        codes.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }
    }

    func testQrCode_ikea4_card() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "1234567890123456789"

        regularItems.reversed().prefix(5).forEach { cart.add($0); cart.setQuantity(5, for: $0) }
        restrictedItems.reversed().prefix(5).forEach { cart.add($0); cart.setQuantity(5, for: $0) }

        let max = 50
        let config = QRCodeConfig(format: .ikea, maxChars: max, finalCode: "END", nextCode: "NEXT", nextCodeWithCheck: "CHECK")

        let codes = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes, [
            "9100003\u{1D}1013\u{1D}921234567890123456789\u{1D}2405\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}2405\u{1D}2405\u{1D}2405\u{1D}2405\u{1D}2406\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}2406\u{1D}2406\u{1D}2406\u{1D}2406\u{1D}2407\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}2407\u{1D}2407\u{1D}2407\u{1D}2407\u{1D}2408\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}2408\u{1D}2408\u{1D}2408\u{1D}2408\u{1D}2409\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}2409\u{1D}2409\u{1D}2409\u{1D}2409\u{1D}240CHECK",
            "9100003\u{1D}1013\u{1D}240r5\u{1D}240r5\u{1D}240r5\u{1D}240r5\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}240r5\u{1D}240r6\u{1D}240r6\u{1D}240r6\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}240r6\u{1D}240r6\u{1D}240r7\u{1D}240r7\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}240r7\u{1D}240r7\u{1D}240r7\u{1D}240r8\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}240r8\u{1D}240r8\u{1D}240r8\u{1D}240r8\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}240r9\u{1D}240r9\u{1D}240r9\u{1D}240r9\u{1D}240NEXT",
            "9100003\u{1D}1013\u{1D}240r9\u{1D}240END"
            ])

        codes.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }
    }


    func testQrCode_ikea_198() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "1234567890123456789"

        let max = 198
        let config = QRCodeConfig(format: .ikea, maxChars: max)

        let product = Product(sku: "_", name: "_", listPrice: 1, type: .singleItem)
        let code = ScannedCode(scannedCode: "11111111", templateId: "default", lookupCode: "_")
        let item = CartItem(1, product , code, nil, .up)

        cart.add(item)
        cart.setQuantity(13, for: item)

        let codes1 = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes1, [
            "9100003\u{1D}1001\u{1D}921234567890123456789\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111"
        ])
        codes1.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }

        cart.setQuantity(14, for: item)
        let codes2 = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes2, [
            "9100003\u{1D}1002\u{1D}921234567890123456789\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111\u{1D}24011111111",
            "9100003\u{1D}1002\u{1D}24011111111"
        ])
        codes2.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }
    }

    func testQrCode_ikea_sofia() {
        let cart = Mock.shoppingCart()
        cart.customerCard = "1234567890123456789"

        let max = 198
        let config = QRCodeConfig(format: .ikea, maxChars: max)

        let product = Product(sku: "_", name: "sofia", listPrice: 1, type: .preWeighed, referenceUnit: .meter, encodingUnit: .centimeter)
        let code = ScannedCode(scannedCode: "11111111", templateId: "default", lookupCode: "_")
        let item = CartItem(120, product, code, nil, .up)

        cart.add(item)

        let codes1 = QRCodeGenerator(cart: cart, config: config, processId: nil).generateCodes()

        XCTAssertEqual(codes1, [
            "9100003\u{1D}1001\u{1D}921234567890123456789\u{1D}24011111111"
        ])

        codes1.forEach {
            XCTAssertLessThanOrEqual($0.count, max)
        }

    }
}
