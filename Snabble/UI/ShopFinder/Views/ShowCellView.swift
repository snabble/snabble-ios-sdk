//
//  ShowCellView.swift
//  Snabble
//
//  Created by Uwe Tilemann on 17.08.22.
//

import Foundation
import CoreLocation
import SwiftUI

public struct ShopAddressView: View {
    var shop: ShopInfoProvider
    
    public var body: some View {
        Group {
            Text(shop.street)
            Text("\(shop.postalCode) \(shop.city)")
        }
    }
}
public struct ShopDistanceView: View {
    var shop: ShopInfoProvider
//    @EnvironmentObject var model: ShopViewModel
    
    public var body: some View {
        let distance = ShopViewModel.default.formattedDistance(for: shop)
        
        if distance.isEmpty {
            EmptyView()
        } else {
            Text(distance)
        }
    }
}

public struct ShopCellView: View {
    var shop: ShopInfoProvider
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(shop.name)
                .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 0) {
                    ShopAddressView(shop: shop)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            Spacer()
            ShopDistanceView(shop: shop)
        }
    }
}
