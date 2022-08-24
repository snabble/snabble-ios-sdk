//
//  ShopCellView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import CoreLocation
import SwiftUI

public struct ShopCellView: View {
    let shop: ShopProviding
    let distance: Double?

    @Binding var currentShop: ShopProviding?

    private var isCurrentShop: Bool {
        guard let currentShop = currentShop else {
            return false
        }
        return currentShop.id == shop.id
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(shop.name)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 0) {
                    AddressView(provider: shop)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            if isCurrentShop {
                Text(key: "Snabble.Shop.Finder.youarehere")
                    .font(.footnote)
                    .foregroundColor(Color.onAccent())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accent())
                    .cornerRadius(16)
            } else {
                DistanceView(distance: distance)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}
