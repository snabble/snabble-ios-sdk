//
//  CartTests.swift
//  Snabble
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Testing
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

    nonisolated(unsafe) static let formatter = PriceFormatter(2, "de_DE",  "EUR", "€")
}

@Suite(.serialized)
final class ShoppingCartTests {

    init() {
        CodeMatcher.addTemplate("", "ean13_instore",     "2{code:5}{_}{embed:5}{ec}")
        CodeMatcher.addTemplate("", "ean13_instore_chk", "2{code:5}{i}{embed:5}{ec}")
    }

    deinit {
        CodeMatcher.clearTemplates()
    }

    // ensure transmissionCode has priority over scannedCode
    @Test func transmissionCode() {
        let code1 = ScannedCode(scannedCode: "scannedCode", transmissionCode: "xmitCode", templateId: "default", lookupCode: "scannedCode")
        #expect(code1.code == "xmitCode")

        let code2 = ScannedCode(scannedCode: "scannedCode", templateId: "default", lookupCode: "scannedCode")
        #expect(code2.code == "scannedCode")
    }

    // ensure `canMerge` is what it should be
    @Test func mergeability() {
        #expect(Mock.simpleItem1.canMerge)
        #expect(Mock.simpleItem2.canMerge)
        #expect(Mock.depositItem.canMerge)
        #expect(!Mock.preWeighedItem.canMerge)
        #expect(!Mock.pieceItem.canMerge)
        #expect(!Mock.piece0Item.canMerge)
        #expect(!Mock.pricedItem.canMerge)
        #expect(!Mock.discountItem.canMerge)
        #expect(!Mock.globusWeighItem.canMerge)
    }

    // ensure `editable` is what it should be
    @Test func editability() {
        #expect(Mock.simpleItem1.editable)
        #expect(Mock.simpleItem2.editable)
        #expect(Mock.depositItem.editable)
        #expect(!Mock.preWeighedItem.editable)
        #expect(!Mock.pieceItem.editable)
        #expect(Mock.piece0Item.editable)
        #expect(!Mock.pricedItem.editable)
        #expect(!Mock.discountItem.editable)
        #expect(!Mock.globusWeighItem.editable)
    }

    // ensure mergeable entries are merged
    @Test func oneProductMerge() {
        let cart = Mock.shoppingCart()

        cart.add(Mock.simpleItem1)
        cart.add(Mock.simpleItem1)

        #expect(cart.numberOfItems == 1)
        #expect(cart.numberOfProducts == 2)

        cart.add(Mock.simpleItem1)
        #expect(cart.numberOfItems == 1)
        #expect(cart.numberOfProducts == 3)
    }

    // ensure mergeable entries are merged
    @Test func twoProductsMerge() {
        let cart = Mock.shoppingCart()

        cart.add(Mock.simpleItem1)
        cart.add(Mock.simpleItem2)
        cart.add(Mock.simpleItem1)

        #expect(cart.numberOfItems == 2)
        #expect(cart.numberOfProducts == 3)

        cart.add(Mock.simpleItem2)
        #expect(cart.numberOfItems == 2)
        #expect(cart.numberOfProducts == 4)
    }

    // ensure non-mergeable products aren't merged
    @Test func twoProductsNoMerge() {
        let cart = Mock.shoppingCart()
        let item = Mock.preWeighedItem

        cart.add(item)
        cart.add(item)
        cart.add(item)

        #expect(cart.numberOfItems == 3)
        #expect(cart.numberOfProducts == 3)

        cart.remove(at: 0)

        #expect(cart.numberOfItems == 2)
        #expect(cart.numberOfProducts == 2)
    }

    // ensure quantities can be changed on editable products
    @Test func editQuantities() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.simpleItem1)
        #expect(cart.numberOfProducts == 1)
        cart.setQuantity(3, at: 0)
        #expect(cart.numberOfProducts == 3)

        #expect(cart.quantity(of: Mock.simpleItem1) == 3)
    }

    // ensure quantities can be changed on editable products
    @Test func editQuantitiesForItem() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.simpleItem1)
        #expect(cart.numberOfProducts == 1)
        cart.setQuantity(3, for: Mock.simpleItem1)
        #expect(cart.numberOfProducts == 3)

        #expect(cart.quantity(of: Mock.simpleItem1) == 3)
    }

    // ensure quantities aren't changed on non-editable products
    @Test func noEditQuantities() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.preWeighedItem)
        #expect(cart.numberOfProducts == 1)
        cart.setQuantity(3, at: 0)
        #expect(cart.numberOfProducts == 1)
        cart.add(Mock.preWeighedItem)
        #expect(cart.numberOfProducts == 2)

        #expect(cart.quantity(of: Mock.preWeighedItem) == 0)

        // test q=0 for non-existing products
        #expect(cart.quantity(of: Mock.simpleItem1) == 0)
    }

    // ensure item and product counts are correct
    @Test func counts() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.simpleItem1)
        #expect(cart.numberOfProducts == 1)
        #expect(cart.numberOfItems == 1)

        cart.setQuantity(3, for: Mock.simpleItem1)
        #expect(cart.numberOfProducts == 3)
        #expect(cart.numberOfItems == 1)

        #expect(cart.quantity(of: Mock.simpleItem1) == 3)

        cart.add(Mock.simpleItem2)
        #expect(cart.numberOfProducts == 4)
        #expect(cart.numberOfItems == 2)

        cart.add(Mock.pieceItem)
        #expect(cart.numberOfProducts == 5)
        #expect(cart.numberOfItems == 3)

        cart.add(Mock.piece0Item)
        cart.setQuantity(42, for: Mock.piece0Item)
        #expect(cart.numberOfProducts == 47)
        #expect(cart.numberOfItems == 4)

        cart.add(Mock.preWeighedItem)
        #expect(cart.numberOfProducts == 48)
        #expect(cart.numberOfItems == 5)
    }

    // MARK: - price tests

    // test cart's price total calculation
    @Test func simplePrice() {
        let cart = Mock.shoppingCart()

        #expect(cart.total == 0)

        cart.add(Mock.simpleItem1)
        #expect(cart.total == 42)

        cart.add(Mock.simpleItem2)
        #expect(cart.total == 63) // 42 + 21ct

        cart.setQuantity(4, at: 0)
        #expect(cart.total == 126) // 42 + 4*21ct
        cart.remove(at: 0)

        cart.add(Mock.depositItem)
        #expect(cart.total == 157)    // 42 + 115ct

        cart.setQuantity(10, at: 0)
        #expect(cart.total == 1192)    // 42 + 10 * 115ct
    }

    @Test func noPrice() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.zeroPriceItem)

        #expect(cart.total == nil)
    }

    @Test func embeddedPriceData() {
        #expect(Mock.simpleItem1.price == 42)
        #expect(Mock.simpleItem2.price == 21)
        #expect(Mock.depositItem.price == 115)
        #expect(Mock.zeroPriceItem.price == 0)

        #expect(Mock.pricedItem.price == 1234)
        #expect(Mock.pieceItem.price == 228)
        #expect(Mock.preWeighedItem.price == 250)
        #expect(Mock.discountItem.price == 321)
        #expect(Mock.globusWeighItem.price == 180)
        #expect(Mock.globusPieceItem.price == 2016)
    }

    // MARK: - backend tests
    @Test func backendDataSimple() {
        guard case let Cart.Item.product(bci) = Mock.simpleItem1.cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "1")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "1234567890123")
        #expect(bci.price == nil)
        #expect(bci.weight == nil)
        #expect(bci.units == nil)
        #expect(bci.weightUnit == nil)
    }

    @Test func backendDataPreWeighed() {
        guard case let Cart.Item.product(bci) = Mock.preWeighedItem.cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "4")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "2000000001254")
        #expect(bci.price == nil)
        #expect(bci.weight == 125)
        #expect(bci.units == nil)
        #expect(bci.weightUnit == .gram)
    }

    @Test func backendDataPiece() {
        guard case let Cart.Item.product(bci) = Mock.pieceItem.cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "5")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "2000000000121")
        #expect(bci.price == nil)
        #expect(bci.weight == nil)
        #expect(bci.units == 12)
        #expect(bci.weightUnit == .piece)
    }

    @Test func backendDataPriced() {
        guard case let Cart.Item.product(bci) = Mock.pricedItem.cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "6")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "2000000012346")
        #expect(bci.price == 1234)
        #expect(bci.weight == nil)
        #expect(bci.units == nil)
        #expect(bci.weightUnit == .price)
    }

    @Test func backendDataPieceZero() {
        let cart = Mock.shoppingCart()
        cart.add(Mock.piece0Item)
        cart.setQuantity(8, at: 0)
        guard case let Cart.Item.product(bci) = cart.items[0].cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "8")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "2123451000080")
        #expect(bci.price == nil)
        #expect(bci.weight == nil)
        #expect(bci.units == 8)
        #expect(bci.weightUnit == .piece)
    }

    @Test func backendDataDiscount() {
        guard case let Cart.Item.product(bci) = Mock.discountItem.cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "6")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "96xxxx")
        #expect(bci.price == 321)
        #expect(bci.weight == nil)
        #expect(bci.units == nil)
        #expect(bci.weightUnit == nil)
    }

    @Test func backendDataCoupon() {
        let simpleItem = Mock.simpleItem1

        #expect(simpleItem.cartItems.count == 1)
        var itemUUID = "" // for now, we assume that product items are first in the array
        for item in simpleItem.cartItems {
            if case let Cart.Item.product(bci) = item {
                #expect(bci.sku == "1")
                #expect(bci.amount == 1)
                #expect(bci.scannedCode == "1234567890123")
                #expect(bci.price == nil)
                #expect(bci.weight == nil)
                #expect(bci.units == nil)
                #expect(bci.weightUnit == nil)
                itemUUID = bci.id
            }
            if case let Cart.Item.coupon(bci) = item {
                #expect(bci.couponID == "foo")
                #expect(bci.refersTo == itemUUID)
            }
        }
    }

    @Test func backendDataGlobusPiece() {
        guard case let Cart.Item.product(bci) = Mock.globusPieceItem.cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "6")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "98xxxx")
        #expect(bci.price == 48)
        #expect(bci.weight == nil)
        #expect(bci.units == 42)
        #expect(bci.weightUnit == .piece)
    }

    @Test func backendDataGlobusWeigh() {
        guard case let Cart.Item.product(bci) = Mock.globusWeighItem.cartItems[0] else {
            Issue.record("not a product")
            return
        }
        #expect(bci.sku == "6")
        #expect(bci.amount == 1)
        #expect(bci.scannedCode == "98xxxx")
        #expect(bci.price == 1200)
        #expect(bci.weight == 150)
        #expect(bci.units == nil)
        #expect(bci.weightUnit == .gram)
    }

    // MARK: - qr code tests
    @Test func codesForQR() {
        #expect(Mock.simpleItem1.cartItems[0] == QRCodeData(1, "1234567890123"))
        #expect(Mock.simpleItem2.cartItems[0] == QRCodeData(1, "1234567890123"))
        #expect(Mock.depositItem.cartItems[0] == QRCodeData(1, "1234567890123"))
        #expect(Mock.preWeighedItem.cartItems[0] == QRCodeData(1, "2000000001254"))
        #expect(Mock.pieceItem.cartItems[0] == QRCodeData(1, "2000000000121"))
        #expect(Mock.piece0Item.cartItems[0] == QRCodeData(1, "2123450000005"))
        #expect(Mock.pricedItem.cartItems[0] == QRCodeData(1, "2000000012346"))
        #expect(Mock.discountItem.cartItems[0] == QRCodeData(1, "96xxxx"))
        #expect(Mock.globusWeighItem.cartItems[0] == QRCodeData(1, "98xxxx"))
        #expect(Mock.globusPieceItem.cartItems[0] == QRCodeData(1, "98xxxx"))

        let cart = Mock.shoppingCart()
        cart.add(Mock.piece0Item)
        cart.setQuantity(99, at: 0)
        #expect(cart.items[0].cartItems[0] == QRCodeData(1, "2123453000996"))

        cart.remove(at: 0)
        cart.add(Mock.simpleItem1)
        cart.setQuantity(42, at: 0)
        #expect(cart.items[0].cartItems[0] == QRCodeData(42, "1234567890123"))
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
