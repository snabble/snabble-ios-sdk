//
//  ShoppingCartViewModel.swift
//  
//
//  Created by Uwe Tilemann on 13.03.23.
//

import Foundation
import SwiftUI

import SnabbleCore
import SnabbleAssetProviding

public extension ShoppingCart {
    static let textFieldMagic: Int = 0x4711
}

@Observable
open class ShoppingCartViewModel: Swift.Identifiable, Equatable {
    public let id = UUID()

    public static func == (lhs: ShoppingCartViewModel, rhs: ShoppingCartViewModel) -> Bool {
        lhs.id == rhs.id
    }

    public var formatter: PriceFormatter {
        PriceFormatter(SnabbleCI.project)
    }

    public let shoppingCart: ShoppingCart

    public weak var shoppingCartDelegate: ShoppingCartDelegate?

    public var productError: Bool = false
    var productErrorMessage: String = ""

    public var confirmDeletion: Bool = false
    var deletionMessage: String = ""
    var deletionItemIndex: Int?

    public var items = [CartEntry]()

    func index(for item: CartEntry) -> Int? {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return nil
        }
        return index
    }

    private var knownImages = Set<String>()
    internal var showImages = false
    
    public init(shoppingCart: ShoppingCart) {
        self.shoppingCart = shoppingCart

        NotificationCenter.default.addObserver(self, selector: #selector(self.shoppingCartUpdated(_:)), name: .snabbleCartUpdated, object: nil)

        self.setupItems(self.shoppingCart)
    }
    
    // MARK: notification handlers
    @objc private func shoppingCartUpdated(_ notification: Notification) {
        self.shoppingCart.cancelPendingCheckoutInfoRequest()
        
        // ignore notifcation sent from this class
        if let object = notification.object as? ShoppingCartViewModel, object == self {
            return
        }
        
        // if we're on-screen, check for errors from the last checkoutInfo creation/update
        if let error = self.shoppingCart.lastCheckoutInfoError {
            switch error.type {
            case .saleStop:
                if let offendingSkus = error.details?.compactMap({ $0.sku }) {
                    self.showProductError(offendingSkus)
                }
            default:
                break
            }
        }
        
        self.setupItems(self.shoppingCart)
        self.getMissingImages()
    }
    
    private func getMissingImages() {
        let allImages: [String] = self.items.compactMap {
            guard case .cartItem(let item, _) = $0 else {
                return nil
            }
            return item.product.imageUrl
        }
        
        let images = Set(allImages)
        let newImages = images.subtracting(self.knownImages)
        for img in newImages {
            guard let url = URL(string: img) else {
                continue
            }
            let task = Snabble.urlSession.dataTask(with: url) { _, _, _ in }
            task.resume()
        }
        self.knownImages = images
    }
    
    private func setupItems(_ cart: ShoppingCart) {
        var newItems = [CartEntry]()

        // all regular cart items - use actual cart data
        let cartItems = cart.items.map { item in
            CartEntry.cartItem(item, cart.backendCartInfo?.lineItems.filter { $0.id == item.uuid } ?? [])
        }
        newItems.append(contentsOf: cartItems)

        // all coupons
        let coupons = cart.coupons.map { coupon in
            CartEntry.coupon(coupon, cart.backendCartInfo?.lineItems.first { $0.id == coupon.coupon.id })
        }
        newItems.append(contentsOf: coupons)

        // all vouchers
        let vouchers = cart.vouchers.map { voucher in
            CartEntry.voucher(voucher, cart.backendCartInfo?.lineItems.filter { $0.id == voucher.voucher.id } ?? [])
        }
        newItems.append(contentsOf: vouchers)

        // add all discounts (without priceModifiers) for the "total discounts" entry
        if cart.totalCartDiscount != 0 {
            newItems.append(totalDiscountItem)
        }
        checkPendingLookups()
        
        // check if any of the cart items's products has an associated image
        let imgIndex = cart.items.firstIndex { $0.product.imageUrl != nil }
        self.showImages = imgIndex != nil
        
        self.items = newItems
    }
}

extension ShoppingCartViewModel {

    var cartIsEmpty: Bool {
        self.numberOfItems == 0
    }

    /// numberOfItems in shoppingCart = numberOfProducts (shoppingCart.items.count) + numberOfVouchers (shoppingCart.vouchers.count)
    var numberOfItems: Int {
        self.shoppingCart.numberOfItems
    }

    var numberOfProducts: Int {
        self.shoppingCart.numberOfProducts
    }

    var numberOfProductsString: String {
        Asset.localizedString(forKey: "Snabble.Shoppingcart.numberOfItems", arguments: self.numberOfItems)
    }
}
