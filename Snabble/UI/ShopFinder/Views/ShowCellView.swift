//
//  ShowCellView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import CoreLocation
import SwiftUI

public struct ShopCellView: View {
    var shop: ShopInfoProvider
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(shop.name)
                .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 0) {
                    AddressView(provider: shop)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            Spacer()
            ShopDistanceView(shop: shop)
        }
    }
}

public struct ShopDistanceView: View {
    var shop: ShopInfoProvider

    public var body: some View {
        let distance = ShopViewModel.default.formattedDistance(for: shop)

        if distance.isEmpty {
            EmptyView()
        } else {
            Text(distance)
        }
    }
}
