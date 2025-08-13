//
//  CartTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import XCTest
@testable import SnabbleCore

struct Mock {
    static let defaultCode = ScannedCode(scannedCode: "1234567890123", templateId: "default", lookupCode: "1234567890123")

    /// regular product, price = 42ct
    static let simpleItem1 = CartItem(1,
                                      Product(sku: "1", name: "1", listPrice: 42, type: .singleItem),
                                      defaultCode, nil, .up)

    /// regular product, price = 21ct
    static let simpleItem2 = CartItem(1,
                                      Product(sku: "2", name: "2", listPrice: 21, type: .singleItem),
                                      defaultCode, nil, .up)

    /// regular product, price 100ct + 15ct deposit
    static let depositItem = CartItem(1,
                                      Product(sku: "3", name: "3", listPrice: 100, type: .singleItem, deposit: 15),
                                      defaultCode, nil, .up)

    /// pre-weighed product, 125g at 20,00€/kg -> 2,50€
    static let preWeighedItem = CartItem(1,
                                         Product(sku: "4", name: "4", listPrice: 2000, type: .preWeighed, referenceUnit: .kilogram, encodingUnit: .gram),
                                         ScannedCode(scannedCode: "2000000001254", embeddedData: 125, encodingUnit: .gram, templateId: "ean13_instore", lookupCode: "2000000001254"),
                                         nil, .up)

    /// 12 pieces at 19ct/pc, 2,28€
    static let pieceItem = CartItem(1,
                                    Product(sku: "5", name: "5", listPrice: 19, type: .singleItem, referenceUnit: .piece, encodingUnit: .piece),
                                    ScannedCode(scannedCode: "2000000000121", embeddedData: 12, encodingUnit: .piece, templateId: "ean13_instore", lookupCode: "2000000000121"),
                                    nil, .up)

    /// pre-weighed product, encoded price == 12,34€
    static let pricedItem = CartItem(1,
                                     Product(sku: "6", name: "6", listPrice: 99 , type: .singleItem, referenceUnit: .price, encodingUnit: .price),
                                     ScannedCode(scannedCode: "2000000012346", embeddedData: 1234, encodingUnit: .price, templateId: "ean13_instore", lookupCode: "2000000012346"),
                                     nil, .up)


    /// 0 pieces at 19ct/pc, price depends on quantity
    static let piece0Item = CartItem(0,
                                     Product(sku: "8", name: "8", listPrice: 19, type: .singleItem, referenceUnit: .piece, encodingUnit: .piece),
                                     ScannedCode(scannedCode: "12345", embeddedData: nil, encodingUnit: .piece, templateId: "ean13_instore_chk", lookupCode: "12345"),
                                     nil, .up)

    /// 3.21€ from code
    static let discountItem = CartItem(1,
                                       Product(sku: "6", name: "6", listPrice: 19, type: .singleItem),
                                       ScannedCode(scannedCode: "96xxxx", priceOverride: 321, templateId: "edeka_discount", lookupCode: "96xxxx"),
                                       nil, .up)

    /// 42 * 48ct = 20,16€
    static let globusPieceItem = CartItem(1,
                                          Product(sku: "6", name: "6", listPrice: 19, type: .singleItem, referenceUnit: .piece),
                                          ScannedCode(scannedCode: "98xxxx", embeddedData: 42, encodingUnit: .piece, referencePriceOverride: 48, templateId: "globus_weighing", lookupCode: "98xxxx"),
                                          nil, .up)

    /// 150g at 12,00€/kg = 1,80€
    static let globusWeighItem = CartItem(1,
                                          Product(sku: "6", name: "6", listPrice: 19, type: .singleItem, referenceUnit: .kilogram),
                                          ScannedCode(scannedCode: "98xxxx", embeddedData: 150, encodingUnit: .gram, referencePriceOverride: 1200, templateId: "globus_weighing", lookupCode: "98xxxx"),
                                          nil, .up)

    // zero price
    static let zeroPriceItem = CartItem(1,
                                        Product(sku: "0", name: "0", listPrice: 0, type: .singleItem),
                                        defaultCode,
                                        nil, .up)

    /// 2,49€ from code, models a product from the demo project
    static let demoItem = CartItem(1,
                                   Product(sku: "1", name: "1", listPrice: 17, type: .preWeighed, referenceUnit: .piece, encodingUnit: .piece),
                                   ScannedCode(scannedCode: "xxx", embeddedData: 249, encodingUnit: .price, templateId: "ean13_instore_chk", lookupCode: "xxx"),
                                   nil, .up)

    static func shoppingCart() -> ShoppingCart {
        let links = ProjectLinks.empty
        let project = Project("test", links: links)
        let shop = Shop(id: "42", projectId: project.id)
        let cartConfig = CartConfig(shop: shop)

        let cart = ShoppingCart(with: cartConfig)
        cart.removeAll(endSession: false, keepBackup: true)
        cart.customerCard = nil
        
        return cart
    }

    static let formatter = PriceFormatter(2, "de_DE",  "EUR", "€")
}

class ShoppingCartTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        CodeMatcher.addTemplate("", "ean13_instore",     "2{code:5}{_}{embed:5}{ec}")
        CodeMatcher.addTemplate("", "ean13_instore_chk", "2{code:5}{i}{embed:5}{ec}")
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        CodeMatcher.clearTemplates()
    }

    // ensure transmissionCode has priority over scannedCode
    func testCart_transmissionCode() {
        let code1 = ScannedCode(scannedCode: "scannedCode", transmissionCode: "xmitCode", templateId: "default", lookupCode: "scannedCode")
        XCTAssertEqual(code1.code, "xmitCode")

        let code2 = ScannedCode(scannedCode: "scannedCode", templateId: "default", lookupCode: "scannedCode")
        XCTAssertEqual(code2.code, "scannedCode")
    }

    // ensure `canMerge` is what it should be
    func testCart_mergeability() {
        XCTAssertTrue(Mock.simpleItem1.canMerge)
        XCTAssertTrue(Mock.simpleItem2.canMerge)
        XCTAssertTrue(Mock.depositItem.canMerge)
        XCTAssertFalse(Mock.preWeighedItem.canMerge)
        XCTAssertFalse(Mock.pieceItem.canMerge)
        XCTAssertFalse(Mock.piece0Item.canMerge)
        XCTAssertFalse(Mock.pricedItem.canMerge)
        XCTAssertFalse(Mock.discountItem.canMerge)
        XCTAssertFalse(Mock.globusWeighItem.canMerge)
    }

    // ensure `editable` is what it should be
    func testCart_editability() {
        XCTAssertTrue(Mock.simpleItem1.editable)
        XCTAssertTrue(Mock.simpleItem2.editable)
        XCTAssertTrue(Mock.depositItem.editable)
        XCTAssertFalse(Mock.preWeighedItem.editable)
        XCTAssertFalse(Mock.pieceItem.editable)
        XCTAssertTrue(Mock.piece0Item.editable)
        XCTAssertFalse(Mock.pricedItem.editable)
        XCTAssertFalse(Mock.discountItem.editable)
        XCTAssertFalse(Mock.globusWeighItem.editable)
    }

    // ensure mergeable entries are merged
    func testCart_1product_merge() {
        let cart = Mock.shoppingCart()

        cart.add(Mock.simpleItem1)
        cart.add(Mock.simpleItem1)

        XCTAssertEqual(cart.numberOfItems, 1)
        XCTAssertEqual(cart.numberOfProducts, 2)

        cart.add(Mock.simpleItem1)
        XCTAssertEqual(cart.numberOfItems, 1)
        XCTAssertEqual(cart.numberOfProducts, 3)
    }

    // ensure mergeable entries are merged
    func testCart_2products_merge() {
        let cart = Mock.shoppingCart()

        cart.add(Mock.simpleItem1)
        cart.add(Mock.simpleItem2)
        cart.add(Mock.simpleItem1)

        XCTAssertEqual(cart.numberOfItems, 2)
        XCTAssertEqual(cart.numberOfProducts, 3)

        cart.add(Mock.simpleItem2)
        XCTAssertEqual(cart.numberOfItems, 2)
        XCTAssertEqual(cart.numberOfProducts, 4)
    }

    // ensure non-mergeable products aren't merged
    func testCart_2products_no_merge() {
        let cart = Mock.shoppingCart()
        let item = Mock.preWeighedItem

        cart.add(item)
        cart.add(item)
        cart.add(item)

        XCTAssertEqual(cart.numberOfItems, 3)
        XCTAssertEqual(cart.numberOfProducts, 3)

        cart.remove(at: 0)

        XCTAssertEqual(cart.numberOfItems, 2)
        XCTAssertEqual(cart.numberOfProducts, 2)
    }

    // ensure quantities can be changed on editable products
    func testCart_editQuantities() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.simpleItem1)
        XCTAssertEqual(cart.numberOfProducts, 1)
        cart.setQuantity(3, at: 0)
        XCTAssertEqual(cart.numberOfProducts, 3)

        XCTAssertEqual(cart.quantity(of: Mock.simpleItem1), 3)
    }

    // ensure quantities can be changed on editable products
    func testCart_editQuantities2() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.simpleItem1)
        XCTAssertEqual(cart.numberOfProducts, 1)
        cart.setQuantity(3, for: Mock.simpleItem1)
        XCTAssertEqual(cart.numberOfProducts, 3)

        XCTAssertEqual(cart.quantity(of: Mock.simpleItem1), 3)
    }

    // ensure quantities aren't changed on non-editable products
    func testCart_noeditQuantities() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.preWeighedItem)
        XCTAssertEqual(cart.numberOfProducts, 1)
        cart.setQuantity(3, at: 0)
        XCTAssertEqual(cart.numberOfProducts, 1)
        cart.add(Mock.preWeighedItem)
        XCTAssertEqual(cart.numberOfProducts, 2)

        XCTAssertEqual(cart.quantity(of: Mock.preWeighedItem), 0)

        // test q=0 for non-existing products
        XCTAssertEqual(cart.quantity(of: Mock.simpleItem1), 0)
    }

    // ensure item and product counts are correct
    func testCart_counts() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.simpleItem1)
        XCTAssertEqual(cart.numberOfProducts, 1)
        XCTAssertEqual(cart.numberOfItems, 1)

        cart.setQuantity(3, for: Mock.simpleItem1)
        XCTAssertEqual(cart.numberOfProducts, 3)
        XCTAssertEqual(cart.numberOfItems, 1)

        XCTAssertEqual(cart.quantity(of: Mock.simpleItem1), 3)

        cart.add(Mock.simpleItem2)
        XCTAssertEqual(cart.numberOfProducts, 4)
        XCTAssertEqual(cart.numberOfItems, 2)

        cart.add(Mock.pieceItem)
        XCTAssertEqual(cart.numberOfProducts, 5)
        XCTAssertEqual(cart.numberOfItems, 3)

        cart.add(Mock.piece0Item)
        cart.setQuantity(42, for: Mock.piece0Item)
        XCTAssertEqual(cart.numberOfProducts, 47)
        XCTAssertEqual(cart.numberOfItems, 4)

        cart.add(Mock.preWeighedItem)
        XCTAssertEqual(cart.numberOfProducts, 48)
        XCTAssertEqual(cart.numberOfItems, 5)
    }

    // MARK: - price tests

    // test cart's price total calculation
    func testCart_simplePrice() {
        let cart = Mock.shoppingCart()

        XCTAssertEqual(cart.total!, 0)

        cart.add(Mock.simpleItem1)
        XCTAssertEqual(cart.total!, 42)

        cart.add(Mock.simpleItem2)
        XCTAssertEqual(cart.total!, 63) // 42 + 21ct

        cart.setQuantity(4, at: 0)
        XCTAssertEqual(cart.total!, 126) // 42 + 4*21ct
        cart.remove(at: 0)

        cart.add(Mock.depositItem)
        XCTAssertEqual(cart.total!, 157)    // 42 + 115ct

        cart.setQuantity(10, at: 0)
        XCTAssertEqual(cart.total!, 1192)    // 42 + 10 * 115ct
    }

    func testCart_noprice() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.zeroPriceItem)

        XCTAssertNil(cart.total)
    }

    func testCart_embeddedPriceData() {
        XCTAssertEqual(Mock.simpleItem1.price, 42)
        XCTAssertEqual(Mock.simpleItem2.price, 21)
        XCTAssertEqual(Mock.depositItem.price, 115)
        XCTAssertEqual(Mock.zeroPriceItem.price, 0)

        XCTAssertEqual(Mock.pricedItem.price, 1234)
        XCTAssertEqual(Mock.pieceItem.price, 228)
        XCTAssertEqual(Mock.preWeighedItem.price, 250)
        XCTAssertEqual(Mock.discountItem.price, 321)
        XCTAssertEqual(Mock.globusWeighItem.price, 180)
        XCTAssertEqual(Mock.globusPieceItem.price, 2016)
    }

    // MARK: - backend tests
    func testCart_backenddata_simple() {
        guard case let Cart.Item.product(bci) = Mock.simpleItem1.cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "1")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "1234567890123")
        XCTAssertEqual(bci.price, nil)
        XCTAssertEqual(bci.weight, nil)
        XCTAssertEqual(bci.units, nil)
        XCTAssertEqual(bci.weightUnit, nil)
    }

    func testCart_backenddata_preWeighed() {
        guard case let Cart.Item.product(bci) = Mock.preWeighedItem.cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "4")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "2000000001254")
        XCTAssertEqual(bci.price, nil)
        XCTAssertEqual(bci.weight, 125)
        XCTAssertEqual(bci.units, nil)
        XCTAssertEqual(bci.weightUnit, .gram)
    }

    func testCart_backenddata_piece() {
        guard case let Cart.Item.product(bci) = Mock.pieceItem.cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "5")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "2000000000121")
        XCTAssertEqual(bci.price, nil)
        XCTAssertEqual(bci.weight, nil)
        XCTAssertEqual(bci.units, 12)
        XCTAssertEqual(bci.weightUnit, .piece)
    }

    func testCart_backenddata_priced() {
        guard case let Cart.Item.product(bci) = Mock.pricedItem.cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "6")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "2000000012346")
        XCTAssertEqual(bci.price, 1234)
        XCTAssertEqual(bci.weight, nil)
        XCTAssertEqual(bci.units, nil)
        XCTAssertEqual(bci.weightUnit, .price)
    }

    func testCart_backenddata_piece0() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.piece0Item)
        cart.setQuantity(8, at: 0)
        guard case let Cart.Item.product(bci) = cart.items[0].cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "8")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "2123451000080")
        XCTAssertEqual(bci.price, nil)
        XCTAssertEqual(bci.weight, nil)
        XCTAssertEqual(bci.units, 8)
        XCTAssertEqual(bci.weightUnit, .piece)
    }

    func testCart_backenddata_discount() {
        guard case let Cart.Item.product(bci) = Mock.discountItem.cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "6")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "96xxxx")
        XCTAssertEqual(bci.price, 321)
        XCTAssertEqual(bci.weight, nil)
        XCTAssertEqual(bci.units, nil)
        XCTAssertEqual(bci.weightUnit, nil)
    }

    func testCart_backenddata_coupon() {
        let simpleItem = Mock.simpleItem1

        XCTAssertEqual(simpleItem.cartItems.count, 1)
        var itemUUID = "" // for now, we assume that product items are first in the array
        for item in simpleItem.cartItems {
            if case let Cart.Item.product(bci) = item {
                XCTAssertEqual(bci.sku, "1")
                XCTAssertEqual(bci.amount, 1)
                XCTAssertEqual(bci.scannedCode, "1234567890123")
                XCTAssertEqual(bci.price, nil)
                XCTAssertEqual(bci.weight, nil)
                XCTAssertEqual(bci.units, nil)
                XCTAssertEqual(bci.weightUnit, nil)
                itemUUID = bci.id
            }
            if case let Cart.Item.coupon(bci) = item {
                XCTAssertEqual(bci.couponID, "foo")
                XCTAssertEqual(bci.refersTo, itemUUID)
            }
        }
    }

    func testCart_backenddata_globusPiece() {
        guard case let Cart.Item.product(bci) = Mock.globusPieceItem.cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "6")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "98xxxx")
        XCTAssertEqual(bci.price, 48)
        XCTAssertEqual(bci.weight, nil)
        XCTAssertEqual(bci.units, 42)
        XCTAssertEqual(bci.weightUnit, .piece)
    }

    func testCart_backenddata_globusWeigh() {
        guard case let Cart.Item.product(bci) = Mock.globusWeighItem.cartItems[0] else {
            return XCTFail("not a product")
        }
        XCTAssertEqual(bci.sku, "6")
        XCTAssertEqual(bci.amount, 1)
        XCTAssertEqual(bci.scannedCode, "98xxxx")
        XCTAssertEqual(bci.price, 1200)
        XCTAssertEqual(bci.weight, 150)
        XCTAssertEqual(bci.units, nil)
        XCTAssertEqual(bci.weightUnit, .gram)
    }

    // MARK: - qr code tests
    func testCart_codesForQR() {
        XCTAssertTrue(Mock.simpleItem1.cartItems[0] == QRCodeData(1, "1234567890123"))
        XCTAssertTrue(Mock.simpleItem2.cartItems[0] == QRCodeData(1, "1234567890123"))
        XCTAssertTrue(Mock.depositItem.cartItems[0] == QRCodeData(1, "1234567890123"))
        XCTAssertTrue(Mock.preWeighedItem.cartItems[0] == QRCodeData(1, "2000000001254"))
        XCTAssertTrue(Mock.pieceItem.cartItems[0] == QRCodeData(1, "2000000000121"))
        XCTAssertTrue(Mock.piece0Item.cartItems[0] == QRCodeData(1, "2123450000005"))
        XCTAssertTrue(Mock.pricedItem.cartItems[0] == QRCodeData(1, "2000000012346"))
        XCTAssertTrue(Mock.discountItem.cartItems[0] == QRCodeData(1, "96xxxx"))
        XCTAssertTrue(Mock.globusWeighItem.cartItems[0] == QRCodeData(1, "98xxxx"))
        XCTAssertTrue(Mock.globusPieceItem.cartItems[0] == QRCodeData(1, "98xxxx"))

        let cart = Mock.shoppingCart()
        cart.add(Mock.piece0Item)
        cart.setQuantity(99, at: 0)
        XCTAssertTrue(cart.items[0].cartItems[0] == QRCodeData(1, "2123453000996"))

        cart.remove(at: 0)
        cart.add(Mock.simpleItem1)
        cart.setQuantity(42, at: 0)
        XCTAssertTrue(cart.items[0].cartItems[0] == QRCodeData(42, "1234567890123"))
    }

}

fileprivate struct QRCodeData: Equatable {
    let quantity: Int
    let code: String

    init(_ quantity: Int, _ code: String) {
        self.quantity = quantity
        self.code = code
    }
}

fileprivate extension Cart.Item {
    static func==(_ lhs: Cart.Item, _ rhs: QRCodeData) -> Bool {
        guard case let Cart.Item.product(productItem) = lhs else {
            return false
        }

        return productItem.amount == rhs.quantity && productItem.scannedCode == rhs.code
    }
}
