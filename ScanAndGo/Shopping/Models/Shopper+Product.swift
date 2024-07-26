//
//  ShoppingModel+Product.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 23.06.24.
//

import Foundation

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

extension Product {
    func strikePrice(formatter: PriceFormatter) -> String? {
        guard discountedPrice != nil, discountedPrice != listPrice else {
            return nil
        }
        return formatter.format(listPrice)
    }
}

extension Shopper {
    public func strikePrice(for item: BarcodeManager.ScannedItem) -> String? {
        item.product.strikePrice(formatter: self.priceFormatter)
    }
}
