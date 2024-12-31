//
//  ShoppingCart+Vouchers.swift
//  Snabble
//
//  Created by Uwe Tilemann on 30.12.24.
//

import SnabbleCore
import SnabbleAssetProviding

extension VoucherType {
    var name: String {
        switch self {
        case .depositReturn:
            return Asset.localizedString(forKey: "Snabble.ShoppingCart.DepositReturn.title")
        default:
            return ""
        }
    }
}

extension Voucher {
    var name: String {
        return type.name
    }
}

extension Array where Element == CheckoutInfo.LineItem {
    public var totalPrice: Int {
        self
            .map { $0.totalPrice ?? 0 }
            .reduce(0, +)
    }
}

extension ShoppingCart {
    
    func lineItemsForVoucher(_ voucher: CartVoucher) -> [CheckoutInfo.LineItem]? {
        backendCartInfo?.lineItems.filter { $0.type == LineItemType.depositReturn && $0.refersTo == voucher.uuid }
    }
    
    var voucherItems: [CartEntry] {
        vouchers.map { voucher in
            let returnItems = lineItemsForVoucher(voucher) ?? []
            return CartEntry.voucher(voucher, returnItems)
        }
    }
    
    func vouchersDescription(_ vouchers: [CartVoucher]) -> String {
        vouchers.compactMap { voucher -> String? in
            if let price = lineItemsForVoucher(voucher)?.totalPrice {
                let formattedPrice = PriceFormatter(SnabbleCI.project).format(price)
                return "\(voucher.voucher.name) \(formattedPrice)"
            }
            return "\(voucher.voucher.name)"
        }
        .joined(separator: "\n")
    }
    
    var vouchersDescroption: String { vouchersDescription(vouchers) }
}

