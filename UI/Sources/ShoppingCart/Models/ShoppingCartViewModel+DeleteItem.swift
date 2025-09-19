//
//  File.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.09.25.
//

import Foundation

import SnabbleAssetProviding

extension ShoppingCartViewModel {
    func deleteCart() {
        self.shoppingCartDelegate?.track(.deletedEntireCart)
        // Clear entire cache
        self.shoppingCart.removeAll(endSession: false, keepBackup: false)
    }
    
    private func delete(at index: Int) {
        if case .cartItem(let item, _) = self.items[index] {

            self.shoppingCartDelegate?.track(.deletedFromCart(item.product.sku))
            self.items.remove(at: index)
            self.shoppingCart.removeItem(item)
        } else if case .coupon(let coupon, _) = self.items[index] {
            self.items.remove(at: index)
            self.shoppingCart.removeCoupon(coupon.coupon)
        } else if case .voucher(let voucherItem, _) = self.items[index] {
            self.items.remove(at: index)
            self.shoppingCart.removeVoucher(voucherItem.voucher)
        }

        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
    }
    
    public func delete(item: CartEntry) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        delete(at: index)
    }

    private func confirmDeletion(at index: Int) {
        var name: String?
        
        if case .cartItem(let item, _) = self.items[index] {
            name = item.product.name
        } else if case .coupon(let cartCoupon, _) = self.items[index] {
            name = cartCoupon.coupon.name
        } else if case .voucher(let cartVoucher, _) = self.items[index] {
            name = cartVoucher.voucher.name
        }
        guard let name = name else {
            return
        }
        deletionItemIndex = index
        deletionMessage = Asset.localizedString(forKey: "Snabble.Shoppingcart.removeItem", arguments: name)
        
        confirmDeletion.toggle()
    }
    
    private func confirmDeletion(item: CartEntry) {
        guard let index = index(for: item) else {
            return
        }
        confirmDeletion(at: index)
    }

    func cancelDeletion() {
        deletionMessage = ""
        deletionItemIndex = nil
    }
    
    func processDeletion() {
        guard let index = deletionItemIndex else {
            return
        }
        
        self.delete(at: index)
        
        deletionMessage = ""
        deletionItemIndex = nil
    }
}

extension ShoppingCartViewModel {

    func trash(item: CartEntry) {
        confirmDeletion(item: item)
    }


    func trash(at offset: IndexSet) {
        let index = offset[offset.startIndex]
        confirmDeletion(at: index)
    }
    
}

